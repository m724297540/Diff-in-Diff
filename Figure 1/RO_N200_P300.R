install.packages("glmnet")
library(glmnet)

install.packages("randomForest")
library(randomForest)

#Data generating #Repeated outcomes
set.seed(666)
B=1000
N=200
p=300
s=5
X=array(rnorm(N*B*p,0,1),dim=c(B,N,p))
gamma=c(s:1,rep(0,(p-s)))/s

D=matrix(0,B,N)
z=matrix(0,B,N)
pr=matrix(0,B,N)

for (i in 1:B){
  z[i,] = X[i,,]%*%gamma        # linear combination 
  pr[i,] = 1/(1+exp(-z[i,]))         # P(D=1 given X) Probit
  D[i,] = rbinom(N,1,pr[i,]) 
}


beta1=gamma+0.5
theta=3

e1=matrix(rnorm(B*N,0,0.1),B,N)
e2=matrix(rnorm(B*N,0,0.1),B,N)
e3=matrix(rnorm(B*N,0,0.1),B,N)

Y00=matrix(0,B,N)
Y01=matrix(0,B,N)
Y11=matrix(0,B,N)

for (i in 1:B){
  
  Y00[i,]=X[i,,]%*%beta1+e1[i,]
  Y01[i,]=Y00[i,]+1+e2[i,]
  Y11[i,]=theta+Y01[i,]+e3[i,]
}

Y0=Y00
Y1=Y01*(1-D)+Y11*D





#####################################################################################
#Abadie's Estimator
#ghat = Logti Lasso
#Penalties
lambda=c(0)
for (i in 1:B){
  CV=cv.glmnet(X[i,,],D[i,],family="binomial",alpha=1)
  lambda[i]=CV$lambda.1se
}

thetahat=c(0)
for (i in 1:B){
    #CV=cv.glmnet(X[i,,],D[i,],family="binomial",alpha=1)
    #CV$lambda.1se
  fit=glmnet(X[i,,],D[i,],family="binomial",alpha=1,lambda=lambda[i])
  beta1hat=fit$beta
  ghat=1/(1+exp(-X[i,,]%*%beta1hat))
  
  thetahat[i]=mean((Y1[i,]-Y0[i,])/mean(D[i,])*(D[i,]-ghat)/(1-ghat))
}


hist(thetahat,breaks=100,main="Abadie",xlab="",ylab="")

#HD
###Sample splitting parameters
k=2
k1=c(1:(N/k))
k2=c((N/k+1):(2*N/k))
K=rbind(k1,k2)

#DML
thetabar=c(0)
for (i in 1:B){
  thetaDML=c(0)
  for (q in 1:k){
    #    CV=cv.glmnet(X[i,-K[q,],],D[i,-K[q,]],family="binomial",alpha=1)
    #    CV$lambda.1se
    fit=glmnet(X[i,-K[q,],],D[i,-K[q,]],family="binomial",alpha=1,lambda=lambda[i])
    beta1hat=fit$beta
    
    index=which(D[i,-K[q,]]==0)
    y=Y1[i,-K[q,]]-Y0[i,-K[q,]]
    y=y[index]
    XX=X[i,-K[q,],1:s]
    XX=XX[index,]
    
    
    model=randomForest(XX,y)
    ghat=1/(1+exp(-X[i,K[q,],]%*%beta1hat))
    
    ellhat=predict(model,X[i,K[q,],1:s])
    
    thetaDML[q]=mean((Y1[i,K[q,]]-Y0[i,K[q,]])/mean(D[i,K[q,]])*(D[i,K[q,]]-ghat)/(1-ghat)-(D[i,K[q,]]-ghat)/mean(D[i,K[q,]])/(1-ghat)*ellhat)
    
  }
  thetabar[i]=mean(thetaDML)
}


par(mfrow=c(1,2))
hist(thetahat,breaks=100,main="Abadie",xlab="",ylab="")
hist(thetabar,breaks=100,main="DMLDiD",xlab="",ylab="")



