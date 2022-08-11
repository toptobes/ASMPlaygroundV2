extern srand:proc
extern rand:proc
extern time:proc
extern count_zeros:proc

.code
;; ----------------------------------------------------------------------------
;;	Initializes a time-based random seed for 'rand'.
;; ----------------------------------------------------------------------------
init_srand proc
	push	rbx				; Initialize rand num seed.
	mov		rcx, 0			; Equivalent to:
	call	time			; srand(time(NULL));
	mov		rcx, rax		; Only should be done once
	call	srand			; in the whole program— it
	pop		rbx				; sets it in other files too.

	ret						; 'call rand' is random-er now
init_srand endp

;; ----------------------------------------------------------------------------
;;	'rand' with range 0–rcx (rcx non-inclusive).
;; 
;;  Params: rcx -> Max value (exclusive)
;;
;;	Returns: Random number from aforementioned range
;; ----------------------------------------------------------------------------
rand_with_max proc
	push	rbx			; rcx is saved to rbx to preserve the value
	mov		rbx, rcx	

	call	rand		; Gets a random number

	mov		rcx, rbx
	div		cx			; Basically do rand % max_value
	mov		ax, dx

	pop		rbx
	ret
rand_with_max endp

;; ----------------------------------------------------------------------------
;;	Adds a tile to a non-zero tile in the board; 20% chance for 4, otherwise 2.
;; 
;;  Params: rcx -> board ptr
;; ----------------------------------------------------------------------------
gen_tile proc
	mov		rsi, rcx

	call	count_zeros
	mov		rcx, rax
	test	rcx, rcx
	jz		ZeroZeros

	call	rand_with_max

	xor		r14, r14
	BoardLoop:
		mov		rdx, rax
		dec		rdx

		cmp		dword ptr [rsi + r14 * 2], 0
		cmove	rax, rdx

		inc		r14	
		cmp		rax, 0
		jg		BoardLoop

	mov		rcx, 10
	call	rand_with_max

	cmp		rax, 8
	jl		LessThanEight

	mov		dword ptr [rsi + r14 * 2], 4
	jmp		MoreThanEight

	LessThanEight:
		mov		dword ptr [rsi + r14 * 2], 2

	MoreThanEight:
	ZeroZeros:
	ret
gen_tile endp
end