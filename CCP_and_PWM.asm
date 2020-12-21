;-------------------------------------------------------------------------------
;--------------- P R O J E C T: Test two CCP and generate a PWM ----------------
;-------------------------------------------------------------------------------
;--------- PROGRAMMER: Miguel R.M. ------- Date: 21 december of 2020 -----------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

;*******************************************************************************
;Diagrama de flujo asociado: (no diagram)
;*******************************************************************************
;Program description:
;-------------------------------------------------------------------------------
;    This program is a test realized to implement the result in a real project.
;The end of the same is obtain two PWM outputs when the timebase is proceedant
;of an unique timer, the setpoint for the PWM in this case will proceed from an
;ADC channel (AN0) and it will vary by software to see differents outputs. For
;that it's using CCP units of the PIC18F45K20 microcontroller in compare mode.
;-------------------------------------------------------------------------------    
;*******************************************************************************

;Code starts:
    
;Declaration of the uC employed and the .inc file used
    LIST P=PIC18F45K20
    #INCLUDE <P18F45K20.INC>

;Main configurations for the uC
    CONFIG FOSC=INTIO67			;Internal oscillator (1MHz)
    CONFIG LVP=OFF			;Single Supply ICSP dissabled
    CONFIG PBADEN=OFF			;PORTB<4:0> as I/O on reset
    CONFIG WDTEN=OFF			;Watch dog timer dissabled
    
;Memory positions for data
    CBLOCK 0x00
	measure				;Stores the result of the A/D conversion
	last_measure			;Stores the result of the A/D conversion
    ENDC
    
    ORG 0x00				;Start position after a reset condition
	goto main
    ORG 0x08				;High priority interrupt direction
	goto High_p_interrupt
    ORG 0x20				;Start position for next line of code
    
main
;-------------------------------------------------------------------------------
;------------------------ START OF THE INITIALIZATION --------------------------
;-------------------------------------------------------------------------------
    
    ;Configuration of the peripherals, pins employed and interrupts:
    ;-Pins:
	;*PortA:
	    bsf TRISA, 0, ACCESS	;Pin A0 as input (Potentiometer [ADC])
	    bsf ANSEL, ANS0, ACCESS	;Digital buffer disabled (pin as analog)
	    
	;*PortB:
	    bsf TRISB, 0, ACCESS	;Pin B0 as input (External SW [INT0])	
	    bcf ANSELH, ANS12, ACCESS	;Digital buffer enabled (pin as digital)
	    
	    bcf TRISB, 5, ACCESS	;Pin B5 as output (for depuration)
	    
	;*PortC:
	    bcf TRISC, 1, ACCESS	;Pin C1 as output (CCP2)
	    bcf TRISC, 2, ACCESS	;Pin C2 as output (CCP1)
	
	;*PortD:
	    bcf TRISD, 0, ACCESS	;Pin D0 as output
	    bcf TRISD, 1, ACCESS	;Pin D1 as output
	    bcf TRISD, 2, ACCESS	;Pin D2 as output
	    bcf TRISD, 3, ACCESS	;Pin D3 as output
	    bcf TRISD, 4, ACCESS	;Pin D4 as output
	    bcf TRISD, 5, ACCESS	;Pin D5 as output
	    bcf TRISD, 6, ACCESS	;Pin D6 as output
	    bcf TRISD, 7, ACCESS	;Pin D7 as output
	    
    ;-Peripherals:
	;*ADC:
	    clrf ADCON0, ACCESS		;ADCON0 register all to 0
	    bsf ADCON0, ADON, ACCESS	;Starts the ADC
	
	    bcf ADCON1, VCFG1, ACCESS	;Selects Vss as source
	    bcf ADCON1, VCFG0, ACCESS	;Selects Vdd as source
	    
	    movlw B'00111000'
	    movwf ADCON2, ACCESS	;Sets ADCON2 register
	    
	;*TMR3: (period of the PWM)
	    movlw B'01110100'
	    movwf T3CON, ACCESS		;Sets T3CON register
	
	    ;Now do the recharge to period 10ms [f=100Hz]
	    movlw 0xFF
	    movwf TMR3H, ACCESS		;Recharge the high part of register
	    movlw 0x06
	    movwf TMR3L, ACCESS		;Recharge the low part of register
	    
	;*CCP1:
	    movlw B'00001010'
	    movwf CCP1CON, ACCESS	;Sets CCP in compare mode (generate int)
	    
	    ;Now initializes compare register to 0 (PWM with the less D.C.)
	    movlw 0xFF
	    movwf CCPR1H, ACCESS
	    
	    movlw 0x06
	    movwf CCPR1L, ACCESS
	    
	;*CCP2:
	    movlw B'00001010'
	    movwf CCP2CON, ACCESS	;Sets CCP in compare mode
	    
	    ;Now initializes compare register to 25% of PWM D.C.
	    movlw 0xFF
	    movwf CCPR2H, ACCESS
	    
	    movlw 0x44
	    movwf CCPR2L, ACCESS
	    
    ;-Interrupts:
	;*Global:
	    bsf INTCON, GIE, ACCESS	;General interrupt enable
	    bsf INTCON, GIEL, ACCESS	;Peripheral interrupt enabled
	    
	;This for if in future puts lower interrupts
	    ;bsf RCON, IPEN, ACCESS	;Priority in interrupts enabled
	    
	;*ADC:
	    bcf PIR1, ADIF, ACCESS	;Clears the flag
	    bsf PIE1, ADIE, ACCESS	;Interrupt enabled
	    bsf IPR1, ADIP, ACCESS	;and set to high priority
	    
	;*TMR3:
	    bcf PIR2, TMR3IF, ACCESS	;Clears the flag
	    bsf PIE2, TMR3IE, ACCESS	;Interrupt enabled
	    bsf IPR2, TMR3IP, ACCESS	;and set to high priority
	    
	;*CCP1:
	    bcf PIR1, CCP1IF, ACCESS	;Clears the flag
	    bsf PIE1, CCP1IE, ACCESS	;Interrupt enabled
	    bsf IPR1, CCP1IP, ACCESS	;and set it to high priority
	
	;*CCP2:
	    bcf PIR2, CCP2IF, ACCESS	;Clears the flag
	    bsf PIE2, CCP2IE, ACCESS	;Interrupt enabled
	    bsf IPR2, CCP2IP, ACCESS	;and set it to high priority
	
    ;Set start to peripheral units:
	bsf T3CON, TMR3ON, ACCESS	;Starts timer count
	bsf ADCON0, GO, ACCESS		;Starts a conversion
    
;-------------------------------------------------------------------------------
;-------------------------- END OF THE INITIALIZATION --------------------------
;-------------------------------------------------------------------------------
    
    bra $				;Infinite loop
    
High_p_interrupt
    btfss PIR1, ADIF, ACCESS		;Enters for the ADC?
    bra Timer3
    
    ;If yes, then execute next program:
	movff ADRESH, LATD		;Represents the conversion on PORTD
	
	movf ADRESH, W, ACCESS		;Store result on the WREG
	movwf measure, ACCESS		;Stores the result on the variable
	movwf last_measure, ACCESS	;Stores the result on the variable
	movwf CCPR1L, ACCESS		;Asign ADC conversion to the PWM1
	
	movlw 0x44
	addwf measure, f, ACCESS	;Sum the last content
	
	movff measure, CCPR2L		;Move the content to the PWM2
        
	bcf PIR1, ADIF, ACCESS		;Clears the flag
	
	bsf ADCON0, GO, ACCESS		;Initialize the conversion again
    
	bra return_high
    
Timer3
    btfss PIR2, TMR3IF, ACCESS		;Enters for the TMR3?
    bra CCP1_int
    
    ;If yes, then recharge timer:
	btg LATB, 5, ACCESS		;For depuration purposes

	movlw 0xFF
	movwf TMR3H, ACCESS		;Recharge the high part of register
	movlw 0x06
	movwf TMR3L, ACCESS		;Recharge the low part of register
	
;-------------------------------------------------------------------------------
;------------------------------- CCP PAYLOAD -----------------------------------
;-------------------------------------------------------------------------------
	
	movlw d'249'
	cpfsgt last_measure, ACCESS
	bra no_max
	
	;When it detects this situation then the output it must be HIGH
	bsf LATC, 2, ACCESS		;Let the pin be putted to high
	bsf LATC, 1, ACCESS		;Let the pin be putted to high
	
	bra return_TMR
	
no_max
	movlw d'6'
	cpfslt last_measure, ACCESS
	bra no_min
	
	;When it detects this situation then the output it must be LOW
	bcf LATC, 2, ACCESS		;Let the pin be putted to low
	bcf LATC, 1, ACCESS		;Let the pin be putted to low
	
	bra return_TMR
	
no_min
	;In the rest of cases the output must be HIGH
	bsf LATC, 2, ACCESS		;Let the pin be putted to high
	bsf LATC, 1, ACCESS		;Let the pin be putted to high
	
;-------------------------------------------------------------------------------
;----------------------------- END CCP PAYLOAD ---------------------------------
;-------------------------------------------------------------------------------
	
return_TMR
	    
	bcf PIR2, TMR3IF, ACCESS	;Clears the flag
	
	bra return_high

	
CCP1_int
    btfss PIR1, CCP1IF, ACCESS		;Enters for the CCP1?
    bra CCP2_int
    
    ;If yes, then change the state of the pin:

;-------------------------------------------------------------------------------
;------------------------------ CCP1 PAYLOAD -----------------------------------
;-------------------------------------------------------------------------------
	
	movlw d'249'
	cpfsgt last_measure, ACCESS
	bra max_CCP1
	
	;When it detects this situation then the output it must be HIGH
	nop				;Don't do anything
    
	bra clear_CCP1
	
max_CCP1
	movlw d'6'
	cpfslt last_measure, ACCESS
	bra min_CCP1
	
	;When it detects this situation then the output it must be LOW
	nop				;Don't do anything
	
	bra clear_CCP1
	
min_CCP1
	;In the rest of cases the output must be HIGH
	bcf LATC, 2, ACCESS		;Let the pin be putted low

;-------------------------------------------------------------------------------
;---------------------------- END CCP1 PAYLOAD ---------------------------------
;-------------------------------------------------------------------------------

clear_CCP1
	bcf PIR1, CCP1IF, ACCESS	;Clear the flag
	
	bra return_high	

CCP2_int
    btfss PIR2, CCP2IF, ACCESS		;Enters for the CCP2?
    bra return_high
    
    ;If yes, then change the state of the pin:

;-------------------------------------------------------------------------------
;------------------------------ CCP2 PAYLOAD -----------------------------------
;-------------------------------------------------------------------------------
	movlw d'249'
	cpfsgt last_measure, ACCESS
	bra max_CCP2
	
	;When it detects this situation then the output it must be HIGH
	nop				;Don't do anything
    
	bra clear_CCP2
	
max_CCP2
	movlw d'6'
	cpfslt last_measure, ACCESS
	bra min_CCP2
	
	;When it detects this situation then the output it must be LOW
	nop				;Don't do anything
	
	bra clear_CCP2
	
min_CCP2
	;In the rest of cases the output must be HIGH
	bcf LATC, 1, ACCESS		;Let the pin be putted low
    
    
;-------------------------------------------------------------------------------
;---------------------------- END CCP2 PAYLOAD ---------------------------------
;-------------------------------------------------------------------------------

clear_CCP2 
    bcf PIR2, CCP2IF, ACCESS		;Clear the flag
    
return_high
    retfie FAST				;return, retrieving the contents of FAST
    
    END
