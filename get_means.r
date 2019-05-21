library(lattice)
vars     = c(1,       5,      10,    50,   100,   500,  1000)
rownames = c(0.0001,  0.001,  0.01,  0.1,  1)
colnames = c(1,       5,     10,   100,   1000)

M <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
V <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
J <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
G <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
D <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))
E <- matrix(c(1:30), nrow = 5, byrow = TRUE, dimnames = list(rownames, colnames))

options("scipen"=100, "digits"=4)
for (var in vars){
	i = 1
	j = 1
	for (rf in rownames){
		for (rq in colnames){
			name = paste("opcua_v", var, "_rf", rf, "_rq", rq,
				     "_t60.csv", sep="")

			data <- read.csv(name, header=FALSE, sep=" ")
			M[i,j] <- mean(data$V3,trim=0.05)
			V[i,j] <- var(data$V3)

			a=0
			b=0
			delay = subset(data, V2=="MyVariable0")$V3
			if (length(delay) < 3)
				b = NA	
			else
				for (x in delay)
				{
					b <- rbind(b,abs(x - a))
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
	print(M)
	print(V)
	print(J)
	print(G)
	print(D)
	print(E)
}


