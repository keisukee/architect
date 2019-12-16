; 	sample 1
; $1 = data
; $2 = like a i of 'for'
; $3 = max val 11
; $4 = keeps val 1 for beq
; $5 = LSB of $2
	lui $1,$0,0x10
	addi $2,$0,1
	addi $3,$0,11
	addi $4,$0,1
loop: andi $5,$2,1
	beq $5,$0,skip
	add $1,$1,$2
skip: addi $2,$2,1
	slt $5,$2,$3
	beq $5,$4,loop
	ori $1,$1,0x100
	sw $1,84($0)
