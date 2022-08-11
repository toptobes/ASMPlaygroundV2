extern getchar:proc

;; Directions:
;;  - left -> 0
;;  - up -> 1
;;  - right -> 2
;;  - down -> 3

.data
up		db	3
right	db	2
down	db	1
left	db	0

.code
IF_KEY_THEN macro key, direction
	movzx	rcx, direction
	cmp		rbx, key
	cmove	rax, rcx
	je		Finished
endm

get_next_direction proc
	push	rbx

	sub		rsp, 32
	call	getchar
	add		rsp, 32

	mov		rbx, rax
	
	call	flush_input

	IF_KEY_THEN		"w", up
	IF_KEY_THEN		"a", left
	IF_KEY_THEN		"s", down
	IF_KEY_THEN		"d", right

	IF_KEY_THEN		"h", left
	IF_KEY_THEN		"j", down
	IF_KEY_THEN		"k", up
	IF_KEY_THEN		"l", right

	mov		rax, -1

	Finished:
		pop	rbx
		ret
get_next_direction endp

flush_input	proc
	sub		rsp, 32

	ReadLoop:
		call	getchar

		cmp		rax, 10
		je		Flushed

		cmp		rax, -1
		je		Flushed

		jmp	ReadLoop

	Flushed:
		add		rsp, 32
		ret
flush_input	endp
end