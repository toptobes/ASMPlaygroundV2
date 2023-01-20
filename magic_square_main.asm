extern _CRT_INIT:proc
extern printf:proc
extern snprintf:proc
extern scanf:proc
extern GetProcessHeap:proc
extern HeapAlloc:proc

.data
matrix_ptr           dq ? ; Pointer to the start of the magic square matrix
sqr_size             dd ? ; Holds the size of the square's side lengths

runtime_option_str   db "Would you like to [M]ake or [C]heck a (normal) magic square? ", 0
invalid_char_str     db 10, "Invalid option. Returning...", 10, 0
invalid_number_str   db 10, "Uhhhhhhh even numbers aren't supported ksorrybai", 10, 0

enter_size_str       db 10, "# of columns? ", 0
enter_matrix_str     db 10, "Enter each number (seperated by newline):", 10, 0

number_fmt           db "%d", 0
number_list_fmt      db 8 dup(0) ; Will be created on the fly depending on width of largest number in the end matrix
number_list_fmt_fmt  db "%%%dd, ", 0
char_fmt	     db "%c", 0
newline_str	     db 10, 0

is_magic_square_str  db 10, "The given IS a normal magic square", 10, 0
not_magic_square_str db 10, "The given is NOT a NORMAL magic square", 10, 0

heres_ur_square_str  db 10, "Here's your generated magic square:", 10, 0

.code
;-------------------------------------------------------------------------------------
; Utility macro for calling a method and balancing stack at same time
;-------------------------------------------------------------------------------------
CALL_BALANCED1 macro method 
	sub     rsp, 32
	call    method
	add     rsp, 32
endm

;-------------------------------------------------------------------------------------
; The above, but also pushes and pops rbp when needed for some reason
;-------------------------------------------------------------------------------------
CALL_BALANCED2 macro method 
	push	rbp
	CALL_BALANCED1 method
	pop	rbp
endm

;-------------------------------------------------------------------------------------
; The entry point into the magic square machine
;-------------------------------------------------------------------------------------
magic_square_main proc
	mov     rcx, offset runtime_option_str ; Prints a question posing if the user wants to create
	CALL_BALANCED1 printf                  ; or test a (normal) magic square
	
	sub	rsp, 8                         ; Allocating a balanced amount of space on the stack for the input
	
	mov     rcx, offset char_fmt           ; Gets the response via scanf which takes in a format to read
	mov     rdx, rsp                       ; which is a single char in this context
	CALL_BALANCED1 scanf                   ; and stores it on the stack which I gave it a pointer to
	
	pop	rax                            ; Puts the input into rax
	
	cmp     rax, "c"                       ; Now just a whole lotta tests to see if the user
	jz      TestMagicSquare                ; wants to test or create a magic square
	
	cmp     rax, "C"
	jz      TestMagicSquare
	
	cmp     rax, "m"
	jz      MakeMagicSquare
	
	cmp     rax, "M"
	jz      MakeMagicSquare
	
	jmp     InvalidChar                    

	MakeMagicSquare:
		call	make_magic_square
		jmp     Exit
	
	TestMagicSquare:
		call    test_magic_square
		jmp     Exit
	
	InvalidChar:
		mov     rcx, offset invalid_char_str   ; If they didn't put 'c' or 'm', then we just give an error            
		CALL_BALANCED1 printf                  ; message and exit early
	
	Exit:
	xor     rax, rax
	ret
magic_square_main endp

;-------------------------------------------------------------------------------------
; Gets the desired square size from the user and stores it in 'sqr_size'
;-------------------------------------------------------------------------------------
get_sqr_size proc
	mov     rcx, offset enter_size_str     ; Asks for the desired size of the square 
	CALL_BALANCED1 printf
	
	sub	rsp, 8                         ; Allocates space on the stack for a response

        mov     rcx, offset number_fmt         ; Reads in the user's response and stores it
	mov     rdx, rsp                       ; at the stack pointer I gave it with the same
	CALL_BALANCED1 scanf                   ; method as before

	pop	rax                            ; Pops the stack and stores the input in rax
	mov	qr_size, eax                   ; and moves it into the 32-bit variable holding the size
	
	ret
get_sqr_size endp

;-------------------------------------------------------------------------------------
; Allocates an approriate amount of zerod out memory for the square
;-------------------------------------------------------------------------------------
alloc_sqr_mem proc
        mov     ecx, sqr_size		       ; Uses the WIN32 API to allocate memory on the heap,
	imul	rcx, rcx		       ; the amount of which is determined by the equation
	shl     rcx, 2			       ; (sqr_size ^ 2) * 4
	                                       ; The * 4 is because they're all dwords, i.e. 4 bytes wide
	call    GetProcessHeap                 ; It first has to get the handle to the default process
					       ; heap via 'GetProcessHeap' before it can allocate memory
	mov     r8,  rcx
	mov     rcx, rax                       ; We pass in 12 to rdx, which == 0b1100, which are the flags for
	mov     rdx, 12                        ; HEAP_GENERATE_EXCEPTIONS & HEAP_ZERO_MEMORY
	
	sub     rsp, 32	                       ; Finally, with the handle to the heap, we can allocate memory
	call    HeapAlloc                      ; from the heap
	add     rsp, 32

	mov     matrix_ptr, rax                ; We then just chuck the pointer that HeapAlloc returns into the
	mov	rax, qword ptr [matrix_ptr]    ; matrix_ptr variable
	mov	matrix_ptr, rax                ; Have to do some janky stuff to shove it in there
	
	ret
alloc_sqr_mem endp

;-------------------------------------------------------------------------------------
; The entry point into the generation branch
;-------------------------------------------------------------------------------------
make_magic_square proc
	call    get_sqr_size                   ; First we need to ask for the desired size

	test    sqr_size, 1                    ; If it's an even number, we just dip
	jz	IsEvenNumber                   ; since I'm too lazy to add even number support as well

	call    alloc_sqr_mem                  ; Need to have memory for the square first

	call	generate_magic_square          ; We'll finally generate the square

	mov	rcx, offset heres_ur_square_str; Now we'll just take the generated square
	CALL_BALANCED2 printf                  ; and print it out, niiice and pretty

	call	print_magic_square
	ret

	IsEvenNumber:
		mov	rcx, offset invalid_number_str
		CALL_BALANCED2 printf

		ret
make_magic_square endp

;-------------------------------------------------------------------------------------
; Does the actual square generation
;-------------------------------------------------------------------------------------
generate_magic_square proc
	mov     r14d, sqr_size                 ; We'll user r14 for quick access to the square's side length
	mov     r13, matrix_ptr                ; and r13 for the matrix pointer
	
	mov     r15, r14                       ; r15 will be for quick access to the overall matrix size
	imul    r15, r14                       ; i.e. side length * side length
					                       
	xor     r8,  r8                        ; r8 will hold the row index,
	mov     r9,  r14                       ; and r9 will hold the column index
	shr     r9,  1                         ; but r9 will be set to the middle column to start
	
	mov     r10, 1                         ; Oh right, and 10 holds the current number to write to the board
		     
	mov     dword ptr [r13 + r9 * 4], r10d ; Speaking of which, we'll write '1' to the board rn, at the top center

	GenerationLoop:
		inc	r10                        ; We need to increment r10 at the start of every loop so we get 0..n^2 written

		dec	r8                         ; Row pointer up 1
		xor	rax, rax
		cmp	r8,  -1                    ; If underflow, reset to the bottom of the matrix
		cmove	rax, r14
		add	r8,  rax

		inc	r9                         ; Col pointer right 1
		xor	rax, rax
		cmp	r9,  r14                   ; If overflow, reset to the left of the matrix
		cmove	rax, r14
		sub	r9,  rax

		BacktrackingLoop:
			mov		rax, r8                    ; Convert r8 and r9 into a definite offset
			imul	        rax, r14   
			add		rax, r9

			mov		ecx, dword ptr [r13 + rax * 4] ; and now check if the spot is occupied or not
			test	        ecx, ecx                       ; If it's 0, it's unoccupied and we can write to it
			jz		WriteNumber                    ; If not, it's backtracking time

			inc		r8                             ; Move row down 1 to reset back to the previous row
			xor		rax, rax
			cmp		r8,  r14                       ; If overflow, reset to 0
			cmove	        rax, r14
			sub		r8,  rax

			inc		r8                             ; Move row down 1 more to get to the row below the original one
			xor		rax, rax
			cmp		r8,  r14                       ; Again, check for overflow
			cmove	        rax, r14
			sub		r8,  rax

			dec		r9                             ; Move col left one to reset back to the previous col
		    xor		rax, rax
		    cmp		r9,  -1                            ; If underflow, reset to the rightmost col
		    cmove	rax, r14
		    add		r9,  rax

			jmp	    BacktrackingLoop               ; and then do it all again until we find a number not written to

		WriteNumber:

		mov	dword ptr [r13 + rax * 4], r10d    ; Once we find an unoccupied slot, we can finally write to it

		cmp	r10, r15                           ; While r10 is less then r15
		jb	GenerationLoop                     ; we continue this loop

	ret
generate_magic_square endp

;-------------------------------------------------------------------------------------
; Prints the matrix in a nice and pretty fashion
;-------------------------------------------------------------------------------------
print_magic_square proc
	call	create_num_list_fmt                    ; But first, we need to generate the number fmt so everything is properly aligned

	mov     r10d, sqr_size                         ; using r10 as a loop counter to do something sqr_size times
	mov     r14,  matrix_ptr                       ; r14 for quick matrix pointer access
	xor     r15,  r15                              ; and r15 as an index counter
	
	RowLoop:
		mov     r11d, sqr_size                     ; r11 is also a loop counter
		push	r10                                ; Need to push r10 to restore it after printf clobbers it

		ColumnLoop:
			push	r11                        ; Same with r11

			mov	rcx, offset number_list_fmt    ; Now we print the number at every index
			mov	edx, dword ptr [r14 + r15 * 4]
			CALL_BALANCED1 printf

			pop	r11
			inc	r15
			dec	r11
			jnz	ColumnLoop

		mov		rcx, offset newline_str    ; also print a newline after every sqr_size numbers are printed
		CALL_BALANCED2 printf

		pop	r10
		dec	r10
		jnz	RowLoop

	ret
print_magic_square endp

;-------------------------------------------------------------------------------------
; Creates the number format for printing the matrix in an aligned, pretty fashion
; Generates `"%<x>d, ", 0`, where <x> is the highest number of digits found in the square
; so that everything is nicely aligned when comes printing time
;
; e.g. `"%3d, ", 0`
;
; and yes I know a LUT-esque thing would've been much better, I just wanted to figure this one out
;-------------------------------------------------------------------------------------
create_num_list_fmt proc
	mov     ecx, sqr_size                          ; We find the total size of the matrix (i.e. sqr_size ^ 2)
	imul    rcx, rcx                               ; and put it in rcx
	push	rcx                                    ; and push it to the program stack

	fldlg2                                         ; Now, we push log10(2) to the FPU stack
	fild	qword ptr [rsp]                        ; and then treat rsp as a pointer to what was in rcx and push that on the FPU stack too
	fyl2x                                          ; and then we compute y * log2x with those numbers

	fisttp	qword ptr [rsp]                        ; Now, store the result of that FPU computation back in the program stack
	pop	rax                                    ; and pop it into rax

	inc	rax                                    ; Finally, we add 1 to rax to find the num digits in sqr_size ^ 2 (aka the max value in the matrix)

	mov	rcx, offset number_list_fmt            ; Then, we can just take that number
	mov	rdx, 8                                 ; and pop it into snprintf
	mov	r8,  offset number_list_fmt_fmt        ; with a couple of other things
	mov	r9,  rax                               ; to generate the actual string for us
	CALL_BALANCED2 snprintf                        ; because atp I can't be asked to do it myself

	ret
create_num_list_fmt endp

;-------------------------------------------------------------------------------------
; The entry point into the validation branch
;-------------------------------------------------------------------------------------
test_magic_square proc
	call    get_sqr_size                           ; As before, we need to ask the user for the square's size

	call    alloc_sqr_mem                          ; and then allocate memory for it
	
	call    read_sqr                               ; But now, we actually read in the square from the terminal
	
	call    test_if_magic                          ; and see if it's a (normal) magic square
	
	mov     rcx, offset is_magic_square_str
	mov     rdx, offset not_magic_square_str
	
	test    eax, eax
	cmovz   rcx, rdx
	
	CALL_BALANCED2 printf                          ; Finally, we can print to the terminal if it's a magic square or not, and return
	
	ret
test_magic_square endp

;-------------------------------------------------------------------------------------
; Reads in the user's square from the terminal
;-------------------------------------------------------------------------------------
read_sqr proc
    	mov     r14,  matrix_ptr                       ; We use r14 for quick access to the matrix pointer
	
	xor     r15,  r15                              ; and r15 to hold the total size of the square matrix
    	mov     r15d, sqr_size                         ; i.e. sqr_size ^ 2
	imul    r15,  r15

	mov     rcx, offset enter_matrix_str           ; We print in the prompt telling them to type in their square
	CALL_BALANCED1 printf

	LoopHead:
		mov     rcx, offset number_fmt             ; and now we just loop n^2 times to read in the whole matrix
		lea     rdx, dword ptr [r14]               ; as an array of dwords (32-bit ints)
		
		CALL_BALANCED1 scanf
		
	    	add     r14, 4
		dec     r15
		
		jnz     LoopHead

	ret
read_sqr endp

;-------------------------------------------------------------------------------------
; Hooooooooo boy, this is going to be a doozy to explain
;
; it is also terribly stupid and overcomplicated and only works up to a magic square size of 16
; but I don't care lol I just did it for fun even if parts are inefficient or naive
;-------------------------------------------------------------------------------------
test_if_magic proc
	mov     ecx, sqr_size	    ; Okay, so, we use rcx both for easy access to the square size, but also so I can use cl for shifting later
	mov	r9d, ecx            ; and r9d will be a loop counter doing something sqr_size times
		
	xor	rax, rax            ; Need to zero rax first since working with ax doesn't implicitly zero it out

	mov     ax,  -1             ; So first, we fill ax with 1s (thank you, two's complement)
	shl     ax,  cl             ; and shift it left sqr_size times
	not     ax                  ; and then not it

	                            ; So, if sqr_size is 5 (aka 5x5), it goes
				    ; 1111111111111111 -> 1111111111100000 -> 0000000000011111
				    ; which creates a nice bitmask we're gonna use for some SIMD stuff for fun
		   
	kmovd   k1,  eax            ; We'll load k1 (the first usable avx512 mask register) with that mask now
	
	mov     r10, 1              ; We'll load r10 with 0b00000001 too
	kmovd   k2,  r10            ; and pop that one into r2
		   
	mov     r8,  matrix_ptr     ; right and we're'na user r8 as the matrix ptr and will offset the value later too
	
	vpxor   xmm0, xmm0, xmm0    ; and finally zero out xmm0 (which implicitly clears all of zmm0)

	StraightSumLoop:
		vpaddd      zmm0{k1}{z}, zmm0, zmmword ptr [r8] ; OKAY, so, first we take the first 512 bits of the matrix, and add it to whatever is in
		                                                ; zmm0. zmm0 starts at 0, and keeps adding up

								; This part adds up each of the columns of the magic square

								; Here's the kicker though, we're using the k1 mask to tell the CPU to only
								; modify the first x elements of zmm0, dictated by the parts of k1 which are 1s
								; So, if the bitmask aforementioned is 0000000000011111, we only modify the first
								; 5 elements of zmm0, i.e. only the bits which are part of the current row
								; that's being iterated over, and the rest of the bits are being set to 0
		
		vmovdqu32   zmm2{k1}{z}, zmmword ptr [r8]       ; Here, we're moving the same 512 bits into zmm2 now, but only modifying the first
		                                                ; x elements as aforementioned, so we're ONLY dealing with the current row
		
		vphaddd     ymm3, ymm2, ymm2			; First, we do a horizontal add of the first 256 bits of zmm2, and store it in ymm3
		valignq     zmm2, zmm2, zmm2, 4			; then we swap the first and last 256 bits of zmm2
		vphaddd     ymm4, ymm2, ymm2                    ; and horizontal add the now first bits of zmm2 and then store that in ymm4
		
		vpaddb      ymm3, ymm3, ymm4                    ; Then, we can add ymm3 and ymm4 together and keep the sums in ymm4
		
		vmovd	    edx, xmm3                           ; then we take the first 32 bits and put it in edx
          	vpextrd     eax, xmm3, 1                        ; and keep the second 32 bits in eax
          	add         eax, edx                            ; and add them together
		
		vpbroadcastd    zmm1{k2}, eax                   ; and since Idk how to properly modify certain bits of an AVX512 register, I'm just
								; setting every element in zmm1 to the value of eax, BUT I'm using a mask with only
								; 1 bit set, so in reality, I'm setting one 32-bit chunk of the register at a time
								; to create a makeshift lift of all the row sums temporarily
		
		shl     r10, 1					; I'm moving the set bit in r10 1 bit over so now
		kmovd   k2,  r10			        ; k2 will make us set the next 32 bits in zmm1 in the next iteration
		
		mov     rdx, rcx                                ; To calc the next offset, I'm taking the size of the square
		shl     rdx, 2					; multiplying by 4, as in 4 bytes,
		add     r8,  rdx				; then adding it to r8 so it's the pointer to the next row
		
		dec     r9					; Finally, I just decrement the loop counter. Nice and simple.
		jnz StraightSumLoop				; and we repeat this for every row in the matrix

	mov     r9d, sqr_size                              	; Okay, onto the next section, I'm using r9d as a loop counter again
	mov     edx, r9d					; and edx constantly holds the square size for quick access
	mov     r8,  matrix_ptr					; & r8 holes matrix for quick access too
	xor     rax, rax					; rax will also be a counter, except incrementing up to sqr_size
	xor     r10, r10					; r10 will hold the left-to-right diag offset
	xor     r11, r11                                        ; and r11 will hold the right-to-left offset

	DiagSumLoop:
		mov     rcx, rax                                ; honestly im too lazy to explain this part at this point
		imul    rcx, rdx				; theyre simple instructions its not too hard to figure out
		add     rcx, rax				; its just summing the diagonals of the matrix
		shl     rcx, 2
		add     r10d, dword ptr [r8 + rcx]
			    
		inc     rax
			    
		mov     rcx, rax
		imul    rcx, rdx
		sub     rcx, rax
		shl     rcx, 2
		add     r11d, dword ptr [r8 + rcx]
			    
		dec     r9
		jnz DiagSumLoop

	mov     r9d, sqr_size					; Now, we're preparing for checking the loop for invalid numbers
	shl     r9,  1						; To ensure that it's a normal magic square

	mov	r12, r9
	imul	r12, r12

	xor	rcx, rcx

	InvalidNumberScanLoop:
		mov     r13, rcx
		
		mov     ecx, dword ptr [r8 + rcx * 4]		; First, I'll go to offset 0 in the matrix

		cmp     rcx, 0					; If it's < 0 or > sqr_size ^ 2, then it's not
		jle     FoundInvalidNumber			; in 1..n^2, so it can't be a normal magic square

		cmp     rcx, r12
		jg      FoundInvalidNumber
		
		mov     dword ptr [r8 + r13 * 4], 0		; Then I set the value there to 0, and go to offset ecx in the matrix
								; since each value should be unique, and between 1 and n^2, I can jump throughout 
		dec     r9					; the matrix by going to the offset equal to each of the values in the array and setting 
		jnz     InvalidNumberScanLoop			; them all to 0. If I go to an offset and it's already 0, it emans it's either
								; invalid, or already visited, meaning it's a duplicate, meaning it's not a magic square
	mov	eax, 1
	jmp	DidNotFindInvalidNumber

	FoundInvalidNumber:
		mov	eax, 0
		ret

	DidNotFindInvalidNumber:

	vpbroadcastd    zmm10{k1}{z}, xmm0		; Now for the fun part, comparing the sums to see if they're equal.
							; First, I fill zmm10 with the first number in xmm0, which is one of the sums
							; or at least fill it from indices 0-n, and the rest of the spots are set to 0
	
							; For example, if n is 3 (sqr size is 3), and it was a nromal magic square
							; this is what zmm0 would look like:
							; 15, 15, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	
	vpcmpeqd   k3, zmm0, zmm10			; If it's a normal square, now zmm10 should contain the exact same things zmm0
	vpcmpeqd   k4, zmm1, zmm10			; and zmm1 do, so I'll compare them to see if they're fully equal
							; If they're equal, k3 and k4 should both be filled with 1s
			   
	vmovd      edx, xmm10				; Also I'm moving the first sum from zmm10 to edx (e.g. 15) so I can test eax and ecx too
							; which contain the diagonal sums
			   
	xor	   ecx, ecx				; ecx will contain 0, since cmov needs a register value and can't use immediate values
			   
	kortestw   k3, k3				; We're checking if k3 is full of 1s here, and if so, DON'T set eax to 0
	cmovnc     eax, ecx
			   
	kortestw   k4, k4				; Same with k4 (row sums)
	cmovnc     eax, ecx
			   
	cmp        r10d, edx				; Same with r10 (diag sum)
	cmovne     eax, ecx
			   
	cmp        r11d, edx				; same with r11 (other diag sum)
	cmovne     eax, ecx

	ret						; and we just return, eax is 1 if it's a magic square, 0 if it isn't.
test_if_magic endp
end
