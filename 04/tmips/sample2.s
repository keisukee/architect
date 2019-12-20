;	sample2
	lui $1,$0,hi(data)
	ori $1,$1,lo(data)
	lw $1,0($1)
	addi $2,$0,1
	addi $3,$0,11
	addi $4,$0,1
loop:	add $1,$1,$2
	addi $2,$2,1
	slt $5,$2,$3
	beq $5,$4,loop
	ori $1,$1,0x100
	sw $1,84($0)

data:	.dw 0x100000
