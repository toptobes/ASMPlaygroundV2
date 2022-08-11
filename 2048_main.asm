extern _CRT_INIT:proc
extern print_board:proc
extern init_srand:proc
extern get_next_direction:proc
extern rand_with_max:proc
extern count_zeros:proc
extern ansi_support:proc
extern gen_tile:proc

.data
;board	dw  01, 02, 03, 04,
;			05, 06, 07, 08,
;			09, 10, 11, 12,
;			13, 14, 15, 16,

;board	dw  0, 2, 0, 0,
;			0, 2, 2, 2,
;			0, 2, 2, 4,
;			0, 0, 2, 4,

board	dw	16 dup(0)

.code
CWB macro function
	mov		rcx, offset board
	call	function
endm

;; ----------------------------------------------------------------------------
;;	Entry point of the game.
;; ----------------------------------------------------------------------------
play_2048 proc
	call	ansi_support	; Inits a 'random' seed
	call	_CRT_INIT		; Initialize C Runtime
	call	init_srand		; Inits a 'random' seed

	CWB		gen_tile
	CWB		gen_tile
	
	CWB		print_board
	
	GameLoop:
		call	get_next_direction
		cmp		rax, 0
		jl		Continue
	
		mov		r10, rax
	
		mov		rdx, r10
		CWB		rot_r
	
		CWB		squash_board	
		CWB		add_board	
		CWB		squash_board	
	
		mov		rdx, r10
		CWB		rot_l
	
		CWB		gen_tile
	
		CWB		print_board
	
		Continue:
	
		CWB		count_zeros
	
		test	rax, rax
		jnz		GameLoop

	xor		rax, rax		; Zero-out rax
	ret						; Return with exit code 0
play_2048 endp

;; ----------------------------------------------------------------------------
;;	Moves zeros to the end of the board.
;; 
;;  Params: rcx -> board ptr
;; ----------------------------------------------------------------------------
squash_board proc
	mov		rsi, rcx		; Set the board pointer to the RSI register

	xor		r15, r15		; Outer loop counter
	RowIterations:
		xor		r13, r13	; Inner loop counter1; keeps track of non-0s
		xor		r14, r14	; Inner loop counter2; keeps track of iterations
		ColIterations:
			cmp		word ptr [rsi + r14 * 2], 0
			jz		IsZero

			cmp		r13, r14	; If r13 > r14, don't swap, but still increment ctr1
			jge		R13NotLessThanR14

			movzx		eax, word ptr [rsi + r14 * 2]	; If r13 is less than r14...
			movzx		edx, word ptr [rsi + r13 * 2]	; swap board[r13] and board[r14]
			mov			word ptr [rsi + r13 * 2], ax	; Moving the zeros
			mov			word ptr [rsi + r14 * 2], dx	; ...to the back

			R13NotLessThanR14:

			inc		r13

			IsZero:

			inc		r14
			cmp		r14, 4
			jl		ColIterations	; Go through this loop once per col

		add		rsi, 8

		inc		r15
		cmp		r15, 4
		jl		RowIterations		; Go through this loop once per row
	ret	
squash_board endp

;; ----------------------------------------------------------------------------
;;	Adds together similarly numbered tiles as in traditional 2048.
;; 
;;  Params: rcx -> board ptr
;; ----------------------------------------------------------------------------
add_board proc
	mov		rsi, rcx		; Set the board pointer to the RSI register

	xor		r15, r15		; Outer loop counter
	RowIterations:
		xor		r14, r14	; Inner loop counter
		ColIterations:
			cmp		word ptr [rsi + r14 * 2], 0		; If it's zero...
			jz		Continue							; continue on

			movzx	eax, word ptr [rsi + r14 * 2]		; Move board[r14] and board[r15]
			movzx	ebx, word ptr [rsi + r14 * 2 + 2]	; into registers to compare them

			cmp		eax, ebx							; If they're not the same...
			jnz		Continue							; continue on

			shl		word ptr [rsi + r14 * 2], 1		; Double board[r14]
			mov		word ptr [rsi + r14 * 2 + 2], 0	; Zero-out board[r15]

			Continue:

			inc		r14
			cmp		r14, 3
			jl		ColIterations	; Go through this loop (length(col) - 1) times

		add		rsi, 8

		inc		r15
		cmp		r15, 4
		jl		RowIterations		; Go through this loop once per row
	ret	
add_board endp

;; ----------------------------------------------------------------------------
;;	Rotates the board right <x> times. 
;; 
;;  Params: rcx -> board ptr
;;			rdx -> # rotations
;; ----------------------------------------------------------------------------
rot_r proc
	test	rdx, rdx
	jz		NoRotation

	RotationLoop:
		push	rcx
		push	rdx

		call	rot_90

		pop		rdx
		pop		rcx

		dec		rdx
		cmp		rdx, 0
		jg		RotationLoop

	NoRotation:
		ret
rot_r endp

;; ----------------------------------------------------------------------------
;;	Rotates the board left <x> times. 
;; 
;;  Params: rcx -> board ptr
;;			rdx -> # rotations
;; ----------------------------------------------------------------------------
rot_l proc
	mov		r8, 4
	sub		r8, rdx
	mov		rdx, r8

	call	rot_r
	ret
rot_l endp

;; ----------------------------------------------------------------------------
;;	Rotates the board 90 degrees. 
;;  I am 100% sure there is a MUCH better way to do so.
;; 
;;  Params: rcx -> board ptr
;; ----------------------------------------------------------------------------
rot_90 proc
	push	rbp
	push	rbx

	mov		rsi, rcx		; Set the board pointer to the RSI register

	xor		r15, r15		; Row loop counter
	TranspositonRowIterations:
		mov		r14, r15	; Col loop counter
		inc		r14
		TranspositonColIterations:

			mov			rcx, r15	; Move row counter into rcx
			shl			rcx, 3		; Multiply row counter by 2^3 (8) to get to r15th row

			mov			r8, r14		; Temp move column counter into r8
			shl			r8, 1		; Multiply it by 2^1 (2) to get r14th column

			add			rcx, r8		; Add rcx & r8 to get to [row][column]

			mov			rdx, r15	; Move row counter into rdx
			shl			rdx, 1		; Multiply it by 2^1 (2) to get r15th column

			mov			r8, r14		; Temp move column counter into r8
			shl			r8, 3		; Multiply col counter by 2^3 (8) to get to r14th row

			add			rdx, r8		; Add rdx & r8 to get to [column][row]

			movzx		eax, word ptr [rsi + rcx]	; Swaps board[row][column]
			movzx		ebx, word ptr [rsi + rdx]	; and board[column][row]
			mov			word ptr [rsi + rcx], bx	; to transpose array
			mov			word ptr [rsi + rdx], ax	; using constant space

			inc		r14
			cmp		r14, 4
			jl		TranspositonColIterations	; Go through this loop (4 - (r15 + 1)) times

		inc		r15
		cmp		r15, 4
		jl		TranspositonRowIterations		; Go through this loop once per row


	xor		r15, r15		; Row loop counter
	MatrixReversalRowIterations:
		mov		r14, 4		; Col loop counter
		shr		r14, 1		; Finds midpoint of array
		dec		r14			; Starts from mid-1
		MatrixReversalColIterations:
			
			mov		r13, 4 - 1	; Complement of mid of array
			sub		r13, r14	; Index that is swapped with

			movzx		eax, word ptr [rsi + r13 * 2]	; Swaps
			movzx		ebx, word ptr [rsi + r14 * 2]	; board[r14]
			mov			word ptr [rsi + r13 * 2], bx	; with
			mov			word ptr [rsi + r14 * 2], ax	; board[r13]

			dec		r14
			cmp		r14, 0
			jge		MatrixReversalColIterations	; Go through this loop ((int) length(col)/2) times

		lea		rsi, [rsi + 8]

		inc		r15
		cmp		r15, 4
		jl		MatrixReversalRowIterations		; Go through this loop once per row

	pop		rbx
	pop		rbp
	ret	
rot_90 endp
end