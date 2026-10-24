; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #15: Manipulación de Archivo
; Descripción: Crea un archivo de texto, escribe un valor en él y comprueba que se haya guardado bien.

INCLUDE Irvine32.inc

.data
    nombreArchivo BYTE "Inventario.txt", 0
    texto         BYTE "125", 0
    archivoHandle DWORD ?

    mensajeExito  BYTE "Archivo guardado", 0
    mensajeError  BYTE "El archivo no se guardó correctamente", 0

.code
main PROC

    ; Crear el archivo y revisar que se haya podido
    mov  edx, OFFSET nombreArchivo
    call CreateOutputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   error
    mov  archivoHandle, eax

    ; Escribir el contenido (sin contar el 0 final)
    mov  eax, archivoHandle
    mov  edx, OFFSET texto
    mov  ecx, SIZEOF texto - 1
    call WriteToFile
    jc   errorEscritura

    ; Revisar que se escribieron todos los bytes
    cmp  eax, SIZEOF texto - 1
    jne  errorEscritura

    ; Cerrar el archivo
    mov  eax, archivoHandle
    call CloseFile
    test eax, eax
    jz   error

    ; Todo salió bien
    mov  edx, OFFSET mensajeExito
    call WriteString
    jmp  fin

errorEscritura:
    ; Cerrar el archivo antes de avisar del error
    mov  eax, archivoHandle
    call CloseFile

error:
    mov  edx, OFFSET mensajeError
    call WriteString

fin:
    exit

main ENDP
END main
