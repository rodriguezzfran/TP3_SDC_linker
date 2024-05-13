.equ CODE_SEGM, gdt_code - gdt_start
.equ DATA_SEGM, gdt_data - gdt_start


/** Switch to protected mode **/
.code16                     /** Instrucciones de 16 bits **/
switch_to_protected_mode:
    cli                     /** Desactiva las interrupciones **/
    lgdt gdt_descriptor     /** Carga la dirección de la GDT **/

    mov %cr0, %eax          /** Mueve el contenido del registro CR0 a EAX **/
    orl $0x1, %eax          /** Establece el bit PE (Protection Enable) en EAX **/
    mov %eax, %cr0          /** Mueve el contenido de EAX de vuelta a CR0, activando el modo protegido **/

    ljmp $0x8, $protected_mode /** Salto largo a la etiqueta protected_mode en el segmento de código de 32 bits **/

/** Global Descriptor Table **/
gdt_start:                  /** Inicio de la GDT (Global Descriptor Table) **/
    
    gdt_null:               /** Descriptor nulo **/
        .long 0x0
        .long 0x0 
        
    gdt_code:               /** Descriptor de código **/
        .word 0xffff        /** Limite del segmento (15-0) **/
        .word 0x0           /** Direccion de la base (15-0) **/
        .byte 0x0           /** Direccion de la base (16-23) **/
        .byte 0b10011010    /** Atributos del segmento **/
                            /** Present               (P=1) **/
                            /** Max privilege level   (DPL=00) **/
                            /** Normal segment        (S=1) **/
                            /** Executable            (Type=101) **/
                            /** No adjustable         (Type=101) **/
                            /** Readable              (Type=101) **/
                            /** No accessed           (A=0) **/
        .byte 0b11001111    /** Limite del segmento (19-16) y Atributos **/
                            /** Limit in 4KB pages    (G=1) **/
                            /** 32-bits mode          (Default=1) **/
                            /** Reserved bit **/
                            /** Not available for user(AVL=0) **/
        .byte 0x0           /** Direccion de la base (31-24) **/

        

    gdt_data:               /** Descriptor de datos **/
        .word 0xffff        /** Limite del segmento (15-0) **/
        .word 0x0           /** Direccion de la base (15-0) **/
        .byte 0x0           /** Direccion de la base (16-23) **/
        .byte 0b10010010    /** Atributos del segmento **/
                            /** Present               (P=1) **/
                            /** Max privilege level   (DPL=00) **/
                            /** Normal segment        (S=1) **/
                            /** Not executable        (Type=001) **/
                            /** Data segment          (Type=001) **/
                            /** Writeable             (Type=001) **/
                            /** No accessed           (A=0) **/ 
        .byte 0b11001111    /** Limite del segmento (19-16) y Atributos **/
                            /** Limit in 4KB pages    (G=1) **/
                            /** 32-bits mode          (Big=1) **/
                            /** Reserved bit **/
                            /** Not available for user(AVL=0) **/
        .byte 0x0           /** Direccion de la base (31-24) **/

    gdt_end:

    gdt_descriptor:                       /** Inicio del GDTR (Global Descriptor Table Register) **/
        .word gdt_end -gdt_start -1       /** Tamaño de la GDT **/
        .long gdt_start                   /** Dirección de la GDT **/



/** inicialización del modo protegido **/
.code32
protected_mode:
    /** Inicializar registros y stack pointer **/
    mov $DATA_SEGM, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    mov $0x7000, %ebp
    mov %ebp, %esp

    mov $0x7000, %ebp
    mov %ebp, %esp
    
    /** Salto a la función check_protected_mode **/
    jmp check_protected_mode


/** Verifica si esta activado el modo protegido e imprime un mensaje **/
check_protected_mode:
    mov %cr0, %eax                      /** Carga el registro de control CR0 **/
    test $0x1, %eax                     /** Test del bit 0 (PE) **/
    jnz protected_mode_active           /** Salto si el bit esta en 1 (modo protegido) **/
    jmp protected_mode_not_active

protected_mode_active:
    /** Procesador en modo protegido **/
    call print_message
    jmp continue_execution

protected_mode_not_active:
    /** El procesador no esta en modo protegido **/
    hlt

continue_execution:
    /** Continuar con la ejecucion del programa **/
    hlt


/** Imprimir el mensjae en VGA **/
print_message:
    mov $message, %ecx                  /** Carga la direccion del mensaje en ECX **/
    mov vga, %eax                       /** Carga la direccion del buffer VGA en EAX **/
    
    /** Calcula la direccion de memoria de VGA **/
    mov $160, %edx
    mul %edx
    lea 0xb8000(%eax), %edx
    mov $0x0f, %ah 
loop:
    mov (%ecx), %al                     /** Carga el caracter desde el mensaje a AL **/
    cmp $0, %al                         /** Verificacion del final del mensaje **/
    je end
    
    mov %ax, (%edx)                     /** Escribir el caracter al buffer VGA **/
    
    /** Moverse al siguiente caracter del mensaje y del buffer VGA **/
    add $1, %ecx
    add $2, %edx
    jmp loop
end:
    ret

/** Mensaje a ser impreso **/
message:
    .asciz "Successfully switched to protected mode."

/** Direccion del buffer VGA **/
vga:
    .long 10
