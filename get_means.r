#!/usr/bin/env Rscript
library(lattice)
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
	vars     = c(1,       5,      10,    50,   100,   500,  1000)
} else if (length(args)==1) {
	vars	 = c(args[1])
}

rownames = c(0.0001,  0.001,  0.01,  0.1,  1)
colnames = c(1,       5,     10,   100,   1000)

M <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
V <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
J <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
G <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
D <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
E <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
N <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
R <- matrix(c(1:25), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))

options("scipen"=100, "digits"=4)
for (var in vars){
	i = 1
	j = 1
	for (rf in rownames){
		for (rq in colnames){
			name = paste("opcua_v", var, "_rf", rf, "_rq", rq,
				     "_t60.csv", sep="")

			mydata <- tryCatch({ 
					read.csv(name, header=FALSE, sep=" ")
				},
				error=function(cond){
					message(cond)
					return(NA)
				},
				warning=function(cond){
					message(cond)
					return(NA)
				})
			if (is.na(mydata)){
				N[i,j] <- 0
				R[i,j] <- 0
				next
			}
			#trim 
			nvar = -as.numeric(var)
			data <- mydata[-1:nvar,]

			N[i,j] <- length(data$V3) 

			M[i,j] <- mean(data$V3,trim=0.05)
			V[i,j] <- var(data$V3)

			a=0
			b=0
			delay = subset(data, V2=="MyVariable0")$V3
			R[i,j] <- length(delay) 

			if (length(delay) < 3)
				b = NA	
			else
				for (x in delay)
				{
					b <- rbind(b,(x - a))
					a = x
				}
			J[i,j] <- mean(b,trim=0.05)
			G[i,j] <- var(b)

			c=0
			d=0
			tstamp = subset(data, V2=="MyVariable0")$V1
			if (length(tstamp) < 3)
				c = NA	
			else
				for (y in tstamp)
				{
					c <- rbind(b,y - d)
					d = y
				}
			D[i,j] <- mean(c,trim=0.05)
			E[i,j] <- var(b)

			j = j+1
		}
		j = 1
		i = i+1
	}

	print(var)
	write(var,file=paste("out_",var,sep=""),append = TRUE)
	print("total var")
	write(N,file=paste("out_",var,sep=""),append = TRUE)
	print(N)
	print("per var")
	write(R,file=paste("out_",var,sep=""),append = TRUE)
	print(R)
	print("delay")
	write(M,file=paste("out_",var,sep=""),append = TRUE)
	print(M)
	write(V,file=paste("out_",var,sep=""),append = TRUE)
	print(V)
	print("jitter")
	write(J,file=paste("out_",var,sep=""),append = TRUE)
	print(J)
	write(G,file=paste("out_",var,sep=""),append = TRUE)
	print(G)
	print("interarr")
	write(D,file=paste("out_",var,sep=""),append = TRUE)
	print(D)
	write(E,file=paste("out_",var,sep=""),append = TRUE)
	print(E)
}


