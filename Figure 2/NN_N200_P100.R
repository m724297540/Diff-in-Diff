install.packages("neuralnet")
library(neuralnet)

install.packages("randomForest")
library(randomForest)


#Data generating #Repeated outcomes
set.seed(444)
B=500
N=200
p=100
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
beta2=gamma+1
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
thetahat=c(0)
for (i in 1:B){
  treatment=ifelse(D[i,]==1,'yes','no')
  data1=data.frame(treatment, X[i,,])
  
  nn = neuralnet(treatment~X1+X2+X3+X4+X5, data1, hidden = 1, threshold = 0.01, linear.output = TRUE)
  p1 <- predict(nn, data1, type='prob')
  
  ghat=p1[,2]
  
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
    treatment=ifelse(D[i,-K[q,]]==1,'yes','no')
    data1=data.frame(treatment, X[i,-K[q,],])
    
    nn = neuralnet(treatment~X1+X2+X3+X4+X5, data1, hidden = 1, threshold = 0.01, linear.output = TRUE)
    
    
    treatment=ifelse(D[i,K[q,]]==1,'yes','no')
    data2=data.frame(treatment, X[i,K[q,],])
    
    
    p1 = predict(nn, data2, type = "prob")
    
    ghat=p1[,2]
    
    index=which(D[i,-K[q,]]==0)
    y=Y1[i,-K[q,]]-Y0[i,-K[q,]]
    y=y[index]
    XX=X[i,-K[q,],1:s]
    XX=XX[index,]
    
    
    model=randomForest(XX,y)
    
    ellhat=predict(model,X[i,K[q,],1:s])
    
    thetaDML[q]=mean((Y1[i,K[q,]]-Y0[i,K[q,]])/mean(D[i,K[q,]])*(D[i,K[q,]]-ghat)/(1-ghat)-(D[i,K[q,]]-ghat)/mean(D[i,K[q,]])/(1-ghat)*ellhat)
    
  }
  thetabar[i]=mean(thetaDML)
}


par(mfrow=c(1,2))
hist(thetahat[which(abs(thetahat-3)<0.5)],breaks=100,main="Abadie",xlab="",ylab="")
hist(thetabar[which(abs(thetabar-3)<0.5)],breaks=100,main="DMLDiD",xlab="",ylab="")
