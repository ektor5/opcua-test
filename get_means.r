#!/usr/bin/env Rscript
library(tcltk)
library(lattice)
library(ggplot2)
library(reshape2)
library(ggpubr)
library(gridExtra)
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
	rfs     = c(0.0001,  0.001,  0.01,  0.1,  1)
} else if (length(args)==1) {
	rfs	 = c(args[1])
}

rownames = c(1,       5,      10,    50,   100,   500)
colnames = c(1,       5,     10,   100)

M <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
V <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
J <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
G <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
D <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
E <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
N <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
R <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))
S <- matrix(, nrow = 6, ncol = 4, byrow = TRUE, dimnames = list(rownames, colnames))

tdata <- data.frame()
options("scipen"=100, "digits"=4)
for (rf in rfs){
	i = 1
	j = 1
	tgraph=list()
	for (var in rownames){
		thvars = 60 * var / as.numeric(rf)
		for (rq in colnames){
			name = paste("opcua_v", var, "_rf", rf, "_rq", rq,
				     "_t60.csv", sep="")
			sname = "var_counting.csv"
			svars = read.csv(sname, header=FALSE, sep=" ")

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
				N[i,j] <- NA
				R[i,j] <- NA
				next
			}

			#trim 
			nvar = -as.numeric(var)
			data <- mydata[-1:nvar,]

			N[i,j] <- length(data$V3) 

			M[i,j] <- mean(data$V3)
			V[i,j] <- var(data$V3)

			adelay = subset(data, V2=="MyVariable0")
			delay = adelay$V3
			V4 = as.factor(var)
			newdata <- cbind(data.frame(V1=adelay$V1-adelay$V1[1], V3=abs(adelay$V3), V2=as.factor(rq)),V4)
			tdata <- rbind(tdata,newdata)

			realvar = subset(svars, V1 == var & V2 == rf & V3 == rq)$V4
			#server loss
			S[i,j] <- (thvars - realvar) / thvars
			#client loss
			R[i,j] <- (realvar - length(data$V3))/realvar

			a=0
			b=0
			if (length(delay) < 3)
				b = NA	
			else
				for (x in delay)
				{
					b <- rbind(b,abs(x - a))
					a <- x
				}
			J[i,j] <- mean(b)
			G[i,j] <- var(b)

			tstamp = subset(data, V2=="MyVariable0")$V1
			c=0
			d=tstamp[1]
			if (length(tstamp) < 3)
				c = NA	
			else
				for (y in tstamp)
				{
					c <- rbind(c,y - d)
					d <- y
				}
			D[i,j] <- mean(c)
			E[i,j] <- var(c)

			j = j+1
		}
		j = 1
		i = i+1
	}
	r=1
	for (rq in colnames){
		rqdata  <- subset(tdata, V2==rq)
		tgraph[[r]] <-  ggplot(rqdata, aes(x=V1,y=V3, log=V3, color = factor(V4))) + 
			scale_y_continuous(trans='log2', breaks=c(0.01,0.02,0.1,0.2,1,2,10,20))+
			geom_point(alpha=1/50)+
			geom_smooth(aes(color = factor(V4)))+
			theme_minimal()+
			labs(x = "Time (s)", y = "Delay (s)", color =
			     "Variables", caption=paste("Refresh Rate =",as.numeric(rf),"s",
							"\nRequest Rate =",as.numeric(rq)/1000,"s"))
			r=r+1
	}

	print(rf)
	write(rf,file=paste("out_",rf,sep=""),append = TRUE)
	print("total val received")
	write(N,file=paste("out_",rf,sep=""),append = TRUE)
	print(N)
	print("total val generated")
	print(S)
	print("loss rate")
	write(R,file=paste("out_",rf,sep=""),append = TRUE)
	print(R)
	print("delay")
	write(M,file=paste("out_",rf,sep=""),append = TRUE)
	print(M)
	write(V,file=paste("out_",rf,sep=""),append = TRUE)
	print(V)
	print("jitter")
	write(J,file=paste("out_",rf,sep=""),append = TRUE)
	print(J)
	write(G,file=paste("out_",rf,sep=""),append = TRUE)
	print(G)
	print("interarr")
	write(D,file=paste("out_",rf,sep=""),append = TRUE)
	print(D)
	write(E,file=paste("out_",rf,sep=""),append = TRUE)
	print(E)

	X11()
	cols2 <- colorRampPalette(c("green","white","red"))(256)

	gr  <- list()
	a=1
	names  <- list("Loss Rate\nServer", "Loss Rate\nClient", "Avg. Delay (s)", "Avg. Jitter (s)", "Avg. Interprocess Time (s)")

	#colnames(R) <- c("v1","v5","v10","v100","v1000")
	#rownames(R) <- c("r1","r5","r10","r50","r100","r500","r1000")
	#melted_cormat <- melt(R, varnames=c('RequestTime', 'Variables'),
			      #na.rm = TRUE,factorsAsStrings=TRUE)
	#warnings()
	#lala <- ggplot(data = melted_cormat, aes(Variables, RequestTime, fill=value ))+
		#geom_tile(color = "white")+
		#scale_fill_gradient2(low = "white", high = "red", mid = "green",
				     #midpoint = 0.01, space = "Lab",
				     #name=names[[a]]) +
		#theme_minimal()+
		#theme(axis.text.x = element_text(angle = 45, vjust = 1,
				 #size = 12, hjust = 1))+
		#coord_fixed()+
	#geom_text(aes(Variables, RequestTime, label = sprintf("%0.0f", round(value, digits = 3))), color = "black", size = 4)
	#gr[[a]]   <- lala
	#a = a+1
	#a=1

	for (i in list(S,R,M,J,D))
	{
	colnames(i) <- c("r0.001","r0.005","r0.01","r0.1")
	rownames(i) <- c("v1","v5","v10","v50","v100","v500")
	melted_cormat <- melt(i, varnames=c( 'Variables','RequestTime'),
			      na.rm = TRUE,factorsAsStrings=TRUE)
	warnings()
	lala <- ggplot(data = melted_cormat, aes(Variables, RequestTime, fill=value ))+
		geom_tile(color = "white")+
		scale_fill_gradient2(low = "white", high = "red", mid = "green",
				     midpoint = 0.1, space = "Lab",
				     name=names[[a]]) +
		theme_minimal()+
		theme(axis.text.x = element_text(angle = 45, vjust = 1,
				 size = 12, hjust = 1))+
		coord_fixed()+
		geom_text(aes(Variables, RequestTime, label = sprintf("%0.3f", round(value, digits = 3))), color = "black", size = 4)
	gr[[a]]   <- lala
	a=a+1

	}
	#print( do.call(gkgarrange, c(gr[1:4], widths = c(2, 2), labels = c("a", "b","c","d"))))
	colnames(S) <- c("r0.001","r0.005","r0.01","r0.1")
	rownames(S) <- c("v1","v5","v10","v50","v100","v500")
	melted_sloss <- melt(S, varnames=c( 'Variables','RequestTime'),
			      na.rm = TRUE,factorsAsStrings=TRUE)
	colnames(R) <- c("r0.001","r0.005","r0.01","r0.1")
	rownames(R) <- c("v1","v5","v10","v50","v100","v500")
	melted_closs <- melt(R, varnames=c( 'Variables','RequestTime'),
			      na.rm = TRUE,factorsAsStrings=TRUE)

	subcose  <- subset(melted_sloss, RequestTime=='r0.01')
	subcosa  <- subset(melted_closs, RequestTime=='r0.01')

	print (ggplot()+
		scale_fill_gradient2(low = "white", high = "red", mid = "green",
				     midpoint = 0.1, space = "Lab",
				     name=names[[1]]) +
	       theme_minimal()+
	       #geom_bar(data=subcosa,aes(x=Variables, y=value, color=Variables), stat="identity")+
	       geom_bar(data=subcose,aes(x=Variables, y=value, fill=value), stat="identity"))
	ggsave(paste("bars",rf,".png",sep=""),  width = 4, height = 4)
	#capture <- tk_messageBox(message = "press", detail = "here")

	grid.arrange(grobs=gr,nrow=2,bottom=paste("Update time =",rf))
	capture <- tk_messageBox(message = "press", detail = "here")
	print(gr[3])
	ggsave(paste("matrixes",rf,".png",sep=""),  width = 6, height = 5)

	#grid.arrange(grobs=tgraph,nrow=2,bottom=paste("Update time =",rf,"s"))
	print(tgraph[4])
	ggsave(paste("plots_rq100_",rf,".png",sep=""),  width = 7, height = 4)

	#capture <- tk_messageBox(message = "press", detail = "here")
}


