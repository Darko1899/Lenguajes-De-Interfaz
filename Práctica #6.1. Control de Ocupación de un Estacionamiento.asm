; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #6.1: Control de Ocupación de un Estacionamiento
; Descripción: Lleva la cuenta de los carros que entran y salen de un estacionamiento de 20 lugares.

INCLUDE Irvine32.inc

.data
    msgMenu      BYTE "1. Entrada de carro", 0
    msgSalida    BYTE "2. Salida de carro", 0
    msgOcupacion BYTE "Carros dentro: ", 0
    msgEntrada   BYTE "Entró un carro", 0
    msgSalio     BYTE "Salió un carro", 0
    msgVacio     BYTE "El estacionamiento está vacío", 0
    msgLleno     BYTE "ESTACIONAMIENTO LLENO", 0
    msgOpcion    BYTE "Elige una opción: ", 0
    msgError     BYTE "Opción no válida", 0

    carros       DWORD 0

.code
main PROC

ciclo:
    ; Mostrar cuántos carros hay
    mov  edx, OFFSET msgOcupacion
    call WriteString
    mov  eax, carros
    call WriteDec
    call Crlf

    ; Si ya se llenó, el programa termina
    cmp  carros, 20
    je   lleno

    ; Mostrar las opciones
    mov  edx, OFFSET msgMenu
    call WriteString
    call Crlf

    mov  edx, OFFSET msgSalida
    call WriteString
    call Crlf

    mov  edx, OFFSET msgOpcion
    call WriteString
    call ReadInt

    ; Revisar qué opción eligió
    cmp  eax, 1
    je   entrada

    cmp  eax, 2
    je   salida

    mov  edx, OFFSET msgError
    call WriteString
    call Crlf
    jmp  ciclo

entrada:
    inc  carros
    mov  edx, OFFSET msgEntrada
    call WriteString
    call Crlf
    jmp  ciclo

salida:
    ; No se puede sacar un carro si no hay ninguno
    cmp  carros, 0
    je   vacio

    dec  carros
    mov  edx, OFFSET msgSalio
    call WriteString
    call Crlf
    jmp  ciclo

vacio:
    mov  edx, OFFSET msgVacio
    call WriteString
    call Crlf
    jmp  ciclo

lleno:
    mov  edx, OFFSET msgLleno
    call WriteString
    call Crlf
    exit

main ENDP
END main
