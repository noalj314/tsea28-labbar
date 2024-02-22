;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Mall för lab1 i TSEA28 Datorteknik Y
;;
;; 210105 KPa: Modified for distance version
;;

	;; Ange att koden är för thumb mode
	.thumb
	.text
	.align 2

	;; Ange att labbkoden startar här efter initiering
	.global	main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Ange vem som skrivit koden
;;               student LiU-ID:noalj314
;; + ev samarbetspartner LiU-ID:kevma271
;;
;; Placera programmet här

main:
   	bl inituart                                                             ; Start av programmet
   	bl initGPIOE
   	bl initGPIOF

	;; vi sätter den korrekta koden till 0000
	mov r0,#(0x20001013 & 0xffff)
	movt r0,#(0x20001013 >> 16)
	mov r1, #0
	strb r1,[r0]

	mov r0,#(0x20001012 & 0xffff)
	movt r0,#(0x20001012 >> 16)
	mov r1, #0
	strb r1,[r0]

	mov r0,#(0x20001011 & 0xffff)
	movt r0,#(0x20001011 >> 16)
	mov r1, #0
	strb r1,[r0]

	mov r0,#(0x20001010 & 0xffff)
	movt r0,#(0x20001010 >> 16)
	mov r1, #0
	strb r1,[r0]

activate:
	mov r7, #0
	mov r8, #0 
 	bl activatealarm

clearinp:
 	bl clearinput

unlockkey:
 	bl getkey
 	cmp r4, #0xF
 	beq codeentered  ;; om knapptrycket är F
 	cmp r4, #9
 	bgt clearinp
 	bl addkey
 	b unlockkey

codeentered:
	bl checkcode
	cmp r4, #0
	beq wrongcode
	b deactivate

wrongcode:
	adr r4, wrongstr
	mov r5, #13 ;; längden på strängen som skickas in
	bl printstring
	b clearinp

deactivate:
	bl deactivatealarm
	b lockkey

lockkey:
	bl getkey
 	cmp r4, #0xA
 	bne lockkey
 	b activate

printwrongs:
	push{lr}
	add r8, r8, #0x30 ;; för att göra det till ascci
	mov r0, r8
	bl printchar ;; skriver ut tiotalet
	add r7, r7, #0x30
	mov r0, r7
	bl printchar ;; skriver ut entalet
	sub r8, r8, #0x30 ;; för att få den att kunna räkna igen
	sub r7, r7, #0x30 
	pop{lr}
	bx lr


wrongstr:
	.string "Felaktig kod!", 10, 13
; Funktion: Skriver ut str¨angen mha subrutinen printchar

increment:
	cmp r7, #9
	beq incrementtens
	add r7, r7, #1
	bx lr 

incrementtens:
	add r8, r8, #1
	mov r7, #0
	bx lr

endloop:
	b endloop


printstring:
   push {lr} ;; Spara återvändsadress
   mov r6,#0x0

stringloop:
   ldrb r0, [r4] ;; ladda ett byte från r4 och ha det temporärt i r0
   bl printchar ;; vi printar en karaktär
   add r4, r4, #1 ;; lägg till 1 i r4
   add r6, r6, #1 ;; lägg till 1 i r6
   cmp r5, r6 ;; jämför r5 r6, r5 är ju längden på strängen
   bne stringloop ;; om inte lika så loopar vi tillbaka
   pop {lr} ;; om lika så återvänder vi till länkregistret
   bx lr

; Funktion: T¨ander gr¨on lysdiod (bit 3 = 1, bit 2 = 0, bit 1 = 0, bit 0 = 0)

deactivatealarm:
   	mov r0, #0x8 ;; värde  0000 1000
   	mov r1,#(GPIOF_GPIODATA & 0xffff)
	movt r1,#(GPIOF_GPIODATA >> 16)
   	strb r0, [r1]
	bx lr

activatealarm:
	mov r0, #0x02 ;; värde 0010
	mov r1, #(GPIOF_GPIODATA & 0xffff)
	movt r1, #(GPIOF_GPIODATA >> 16)
	strb r0, [r1]
	bx lr

;; Ovre halvan av programmet motsvarar tangentbordet, d¨ar bitm¨onstret
; f¨or knapparna som trycks l¨aggs ut p˚a bitarna 3-0 i port E, och bit 4 i port E
;; anger om knappen trycks ned eller inte.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Tryckt knappt returneras i r4

getkey:
	mov r1,#(GPIOE_GPIODATA & 0xffff)
	movt r1,#(GPIOE_GPIODATA >> 16)

waitForKeyPress: ;; kollar ifall knappen blir nedtryckt
	ldrb r4, [r1]
	ands r5, r4, #0x10
	beq waitForKeyPress ;; om stroben inte är ett dvs ingen knapp är nedtryckt

waitForKeyUp: ;; kollar ifall knappen fortfarande är nedtryckt
	ldrb r4, [r1]
	ands r5, r4, #0x10
	bne waitForKeyUp
	bx lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Vald tangent i r4
; Utargument: Inga
;
; Funktion: Flyttar inneh˚allet p˚a 0x20001000-0x20001002 fram˚at en byte
; till 0x20001001-0x20001003. Lagrar sedan inneh˚allet i r4 p˚a
; adress 0x20001000.
addkey:
	mov r0,#(0x20001000 & 0xffff)
	movt r0,#(0x20001000 >> 16)
	mov r1,#(0x20001001 & 0xffff)
	movt r1,#(0x20001001 >> 16)
	mov r2,#(0x20001002 & 0xffff)
	movt r2,#(0x20001002 >> 16)
	mov r3,#(0x20001003 & 0xffff)
	movt r3,#(0x20001003 >> 16)


	ldrb r5, [r2]
	strb r5, [r3]
	ldrb r5, [r1]
	strb r5, [r2]
	ldrb r5, [r0]
	strb r5, [r1]
	strb r4, [r0]

	bx lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: S¨atter inneh˚allet p˚a 0x20001000-0x20001003 till 0xFF
clearinput:
; Lagrar alla relevanta minnesadresser till register
	mov r0,#(0x20001000 & 0xffff)
	movt r0,#(0x20001000 >> 16)
	mov r1,#(0x20001001 & 0xffff)
	movt r1,#(0x20001001 >> 16)
	mov r2,#(0x20001002 & 0xffff)
	movt r2,#(0x20001002 >> 16)
	mov r3,#(0x20001003 & 0xffff)
	movt r3,#(0x20001003 >> 16)

; Sätter register r5 till 0xFF och uppdaterar sedan resterande register med det värdet
	mov r5, #0xFF
	strb r5, [r0]
	strb r5, [r1]
	strb r5, [r2]
	strb r5, [r3]

	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Returnerar 1 i r4 om koden var korrekt, annars 0 i r4
;0x20001010–0x20001013: H¨ar ska den korrekta koden finnas lagrad. F¨orsta
;siffran i koden placeras i 0x20001013 och sista siffran i 0x20001010.

checkcode:
	mov r0,#(0x20001010 & 0xffff) ; den korrekta koden
	movt r0,#(0x20001010 >> 16)

	mov r1,#(0x20001000 & 0xffff) ; användarenskod
	movt r1,#(0x20001000 >> 16)
	ldr r2, [r0] ;; korrekt kod laddas
	ldr r3, [r1] ;; fel kod laddas
	cmp r2, r3 ;; jämför korrekt med fel
	bne badCode

	mov r4, #1 ; returnera 1 ifall koden är rätt
	bx lr

badCode:
	mov r4, #0 ; annars returnera 0
	bx lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,
;;;
;;; Allt här efter ska inte ändras
;;;
;;; Rutiner för initiering
;;; Se labmanual för vilka namn som ska användas
;;;

	.align 4

;; 	Initiering av seriekommunikation
;;	Förstör r0, r1

inituart:
	mov r1,#(RCGCUART & 0xffff)		; Koppla in serieport
	movt r1,#(RCGCUART >> 16)
	mov r0,#0x01
	str r0,[r1]

	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x01
	str r0,[r1]		; Koppla in GPIO port A

	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOA_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOA_GPIOAFSEL >> 16)
	mov r0,#0x03
	str r0,[r1]		; pinnar PA0 och PA1 som serieport

	mov r1,#(GPIOA_GPIODEN & 0xffff)
	movt r1,#(GPIOA_GPIODEN >> 16)
	mov r0,#0x03
	str r0,[r1]		; Digital I/O på PA0 och PA1

	mov r1,#(UART0_UARTIBRD & 0xffff)
	movt r1,#(UART0_UARTIBRD >> 16)
	mov r0,#0x08
	str r0,[r1]		; Sätt hastighet till 115200 baud
	mov r1,#(UART0_UARTFBRD & 0xffff)
	movt r1,#(UART0_UARTFBRD >> 16)
	mov r0,#44
	str r0,[r1]		; Andra värdet för att få 115200 baud

	mov r1,#(UART0_UARTLCRH & 0xffff)
	movt r1,#(UART0_UARTLCRH >> 16)
	mov r0,#0x60
	str r0,[r1]		; 8 bit, 1 stop bit, ingen paritet, ingen FIFO

	mov r1,#(UART0_UARTCTL & 0xffff)
	movt r1,#(UART0_UARTCTL >> 16)
	mov r0,#0x0301
	str r0,[r1]		; Börja använda serieport

	bx  lr

; Definitioner för registeradresser (32-bitars konstanter)
GPIOHBCTL	.equ	0x400FE06C
RCGCUART	.equ	0x400FE618
RCGCGPIO	.equ	0x400fe608
UART0_UARTIBRD	.equ	0x4000c024
UART0_UARTFBRD	.equ	0x4000c028
UART0_UARTLCRH	.equ	0x4000c02c
UART0_UARTCTL	.equ	0x4000c030
UART0_UARTFR	.equ	0x4000c018
UART0_UARTDR	.equ	0x4000c000
GPIOA_GPIOAFSEL	.equ	0x40004420
GPIOA_GPIODEN	.equ	0x4000451c
GPIOE_GPIODATA	.equ	0x400240fc
GPIOE_GPIODIR	.equ	0x40024400
GPIOE_GPIOAFSEL	.equ	0x40024420
GPIOE_GPIOPUR	.equ	0x40024510
GPIOE_GPIODEN	.equ	0x4002451c
GPIOE_GPIOAMSEL	.equ	0x40024528
GPIOE_GPIOPCTL	.equ	0x4002452c
GPIOF_GPIODATA	.equ	0x4002507c
GPIOF_GPIODIR	.equ	0x40025400
GPIOF_GPIOAFSEL	.equ	0x40025420
GPIOF_GPIODEN	.equ	0x4002551c
GPIOF_GPIOLOCK	.equ	0x40025520
GPIOKEY		.equ	0x4c4f434b
GPIOF_GPIOPUR	.equ	0x40025510
GPIOF_GPIOCR	.equ	0x40025524
GPIOF_GPIOAMSEL	.equ	0x40025528
GPIOF_GPIOPCTL	.equ	0x4002552c

;; Initiering av port F
;; Förstör r0, r1, r2
initGPIOF:
	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x20		; Koppla in GPIO port F
	str r0,[r1]
	nop 			; Vänta lite
	nop
	nop

	mov r1,#(GPIOHBCTL & 0xffff)	; Använd apb för GPIO
	movt r1,#(GPIOHBCTL >> 16)
	ldr r0,[r1]
	mvn r2,#0x2f		; bit 5-0 = 0, övriga = 1
	and r0,r0,r2
	str r0,[r1]

	mov r1,#(GPIOF_GPIOLOCK & 0xffff)
	movt r1,#(GPIOF_GPIOLOCK >> 16)
	mov r0,#(GPIOKEY & 0xffff)
	movt r0,#(GPIOKEY >> 16)
	str r0,[r1]		; Lås upp port F konfigurationsregister

	mov r1,#(GPIOF_GPIOCR & 0xffff)
	movt r1,#(GPIOF_GPIOCR >> 16)
	mov r0,#0x1f		; tillåt konfigurering av alla bitar i porten
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAMSEL >> 16)
	mov r0,#0x00		; Koppla bort analog funktion
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPCTL & 0xffff)
	movt r1,#(GPIOF_GPIOPCTL >> 16)
	mov r0,#0x00		; använd port F som GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIODIR & 0xffff)
	movt r1,#(GPIOF_GPIODIR >> 16)
	mov r0,#0x0e		; styr LED (3 bits), andra bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPUR & 0xffff)
	movt r1,#(GPIOF_GPIOPUR >> 16)
	mov r0,#0x11		; svag pull-up för tryckknapparna
	str r0,[r1]

	mov r1,#(GPIOF_GPIODEN & 0xffff)
	movt r1,#(GPIOF_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar som digital I/O
	str r0,[r1]

	bx lr


;; Initiering av port E
;; Förstör r0, r1
initGPIOE:
	mov r1,#(RCGCGPIO & 0xffff)    ; Clock gating port (slå på I/O-enheter)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x10		; koppla in GPIO port B
	str r0,[r1]
	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOE_GPIODIR & 0xffff)
	movt r1,#(GPIOE_GPIODIR >> 16)
	mov r0,#0x0		; alla bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAMSEL >> 16)
	mov r0,#0x00		; använd inte analoga funktioner
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPCTL & 0xffff)
	movt r1,#(GPIOE_GPIOPCTL >> 16)
	mov r0,#0x00		; använd inga specialfunktioner på port B
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPUR & 0xffff)
	movt r1,#(GPIOE_GPIOPUR >> 16)
	mov r0,#0x00		; ingen pullup på port B
	str r0,[r1]

	mov r1,#(GPIOE_GPIODEN & 0xffff)
	movt r1,#(GPIOE_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar är digital I/O
	str r0,[r1]

	bx lr


;; Utskrift av ett tecken på serieport
;; r0 innehåller tecken att skriva ut (1 byte)
;; returnerar först när tecken skickats
;; förstör r0, r1 och r2
printchar:
	mov r1,#(UART0_UARTFR & 0xffff)	; peka på serieportens statusregister
	movt r1,#(UART0_UARTFR >> 16)
loop1:
	ldr r2,[r1]			; hämta statusflaggor
	ands r2,r2,#0x20		; kan ytterligare tecken skickas?
	bne loop1			; nej, försök igen
	mov r1,#(UART0_UARTDR & 0xffff)	; ja, peka på serieportens dataregister
	movt r1,#(UART0_UARTDR >> 16)
	str r0,[r1]			; skicka tecken
	bx lr



