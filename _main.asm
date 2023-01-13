extern _CRT_INIT:proc
extern printf:proc
extern scanf:proc
extern GetProcessHeap:proc
extern HeapAlloc:proc

.data
matrix_dbl_ptr dq ?
sqr_size_ptr   dq ?
sums_ptr       dq ?

number_str   db "%d", 0
display_str  db "Un number: %d", 10, 0

.code
main proc
	call    _CRT_INIT
	
	call    get_sqr_size
	
	mov     rcx, 1024
	call    alloc_sqr_mem
	mov     matrix_dbl_ptr, rax
	
	call    read_sqr
	
	call    test_if_magic
	
	xor     rdx, rdx
	
	lea     rcx, display_str
	mov     dl,  byte ptr [sqr_size_ptr]
	
	push    rbp
	sub     rsp, 32
	call    printf
	add     rsp, 32
	pop     rbp
	
	xor     rax, rax
	ret
main endp

get_sqr_size proc
    lea     rcx, number_str
	lea     rdx, sqr_size_ptr
	
	sub     rsp, 32
	call    scanf
	add     rsp, 32
	
	ret
get_sqr_size endp

alloc_sqr_mem proc
	call    GetProcessHeap
	
	mov     r8,  rcx
	mov     rcx, rax
	mov     rdx, 12
	
	sub     rsp, 32
	call    HeapAlloc
	add     rsp, 32
	
	ret
alloc_sqr_mem endp

read_sqr proc
    mov     r14,  matrix_dbl_ptr
	
	xor     r15,  r15
    mov     r15b, byte ptr [sqr_size_ptr]
	imul    r15,  r15

	LoopHead:
		lea     rcx, number_str
		lea     rdx, dword ptr [r14]
		
		sub     rsp, 32
	    call    scanf
	    add     rsp, 32
		
	    add     r14, 4
		dec     r15
		
		jnz     LoopHead

	ret
read_sqr endp

test_if_magic proc
	xor     rcx, rcx
		   
	mov     cl,  byte ptr [sqr_size_ptr]
	movzx   r9,  cl
		   
	xor     eax, eax
		   
	mov     ax,  -1
	shl     ax,  cl
	not     ax
		   
	kmovd   k1,  eax
		   
	mov     r8,  qword ptr [matrix_dbl_ptr]
	
	vmovdqu32    zmm0{k1}{z}, zmmword ptr [r8]
		
	StraightSumLoop:
		mov     rdx, 4
		imul    rdx, rcx
		add     r8,  rdx
		
		vmovdqu32   zmm1{k1}{z}, zmmword ptr [r8]
		
		vpaddd      zmm0, zmm0, zmm1
		
		vphaddd     ymm3, ymm1, ymm1
		valignq     zmm2, zmm1, zmm1, 4
		vphaddd     ymm4, ymm2, ymm2
		
		xor     r10, r10
		xor     r11, r11
		
		vmovd	xmm3, r10d
		vmovd	xmm4, r11d
		add     r10d, r11d
		
		dec r9
		jnz StraightSumLoop

	ret
test_if_magic endp
end
