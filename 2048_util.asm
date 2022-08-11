.code
;; ----------------------------------------------------------------------------
;;	Moves the zeros to the end of the board.
;; 
;;  Params: rcx -> board ptr
;;
;;	Returns: # of zeros in the board
;; ----------------------------------------------------------------------------
count_zeros proc
	xor		r14, r14	; Set loop counter to 0
	xor		rax, rax	; Clear out rax
	mov		rdx, 1		; Readies faux inc register

	BoardLoop:
		mov		rdx, rax	; Sets rdx to 1+rax
		inc		rdx			; Workaround for no conditional increment

		cmp		dword ptr [rcx + r14 * 2], 0
		cmove	rax, rdx	; Increment rax if board[r14] is 0

		inc		r14	
		cmp		r14, 16
		jl		BoardLoop	; Run loop once per tile
	ret
count_zeros endp
end