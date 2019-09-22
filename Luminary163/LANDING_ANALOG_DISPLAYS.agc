### FILE="Main.annotation"
## Copyright:   Public domain.
## Filename:    LANDING_ANALOG_DISPLAYS.agc
## Purpose:     A section of Luminary revision 163.
##              It is part of the reconstructed source code for the first
##              (unflown) release of the flight software for the Lunar
##              Module's (LM) Apollo Guidance Computer (AGC) for Apollo 14.
##              The code has been recreated from a reconstructed copy of
##              Luminary 173, as well as Luminary memos 157 amd 158.
##              It has been adapted such that the resulting bugger words
##              exactly match those specified for Luminary 163 in NASA
##              drawing 2021152N, which gives relatively high confidence
##              that the reconstruction is correct.
## Reference:   pp. 890-898
## Assembler:   yaYUL
## Contact:     Ron Burkey <info@sandroid.org>.
## Website:     www.ibiblio.org/apollo/index.html
## Mod history: 2019-08-21 MAS  Created from Luminary 173. Implemented ACB L-11
##                              by moving three checks as shown in the
##                              Luminary 173 flowcharts.

## Page 891
                BANK    21
                SETLOC  R10
                BANK

                EBANK=  UNIT/R/
                COUNT*  $$/R10

LANDISP         LXCH    PIPCTR1         # UPDATE TBASE2 AND PIPCTR SIMULTANEOUSLY.
                CS      TIME1
                DXCH    TBASE2

                CS      FLAGWRD7        # IS LANDING ANALOG DISPLAYS FLAG SET?
                MASK    SWANDBIT
                CCS     A
                TCF     DISPRSET        # NO.
                CA      IMODES33        # BIT 7 = 0 (DO ALTRATE), =1 (DO ALT.)
                MASK    BIT7
                CCS     A
                TCF     ALTOUT
ALTROUT         TC      DISINDAT        # CHECK MODE SELECT SWITCH AND DIDFLG.
                CS      IMODES33
                MASK    BIT7
                ADS     IMODES33        # ALTERNATE ALTITUDE RATE WITH ALTITUDE.
                CAF     BIT2            # RATE COMMAND IS EXECUTED BEFORE RANGE.
                EXTEND
                WOR     CHAN14          # ALTRATE (BIT2 = 1), ALTITUDE (BIT2 = 0).
ARCOMP          CA      RUNIT           # COMPUTE ALTRATE = RUNIT.VVECT M/CS *2(-6).
                EXTEND
                MP      VVECT           # MULTIPLY X-COMPONENTS.
                XCH     RUPTREG1        # SAVE SINGLE PRECISION RESULT M/CS*2(-6).
                CA      RUNIT +1        # MULTIPLY Y-COMPONENTS.
                EXTEND
                MP      VVECT +1
                ADS     RUPTREG1        # ACCUMULATE PARTIAL PRODUCTS.
                CA      RUNIT +2        # MULTIPLY Z-COMPONENTS.
                EXTEND
                MP      VVECT +2
                ADS     RUPTREG1        # ALTITUDE RATE IN M/CS *2(-6).
                CA      ARCONV          # CONVERT ALTRATE TO BIT UNITS (.5FPS/BIT)
                EXTEND
                MP      RUPTREG1
                DDOUBL
                DDOUBL
                XCH     RUPTREG1        # ALTITUDE RATE IN BIT UNITS*2(-14).
                CA      DALTRATE        # ALTITUDE RATE COMPENSATION FACTOR.
                EXTEND
                MP      DT
                AD      RUPTREG1
                TS      ALTRATE         # ALTITUDE RATE IN BIT UNITS*2(-14).
                CS      ALTRATE
## Page 892
                EXTEND                  # CHECK POLARITY OF ALTITUDE RATE.
                BZMF    +2
                TCF     DATAOUT         # NEGATIVE - SEND POS. PULSES TO ALTM REG.
                CA      ALTRATE         # POSITIVE OR ZERO - SET SIGN BIT = 1 AND
                AD      BIT15           # SEND TO ALTM REGISTER.  *DO NOT SEND +0*
DATAOUT         TS      ALTM            # ACTIVATE THE LANDING ANALOG DISPLAYS - -
                CAF     BIT3
                EXTEND
                WOR     CHAN14          # BIT3 DRIVES THE ALT/ALTRATE METER.
                TCF     TASKOVER        # EXIT

ALTOUT          TC      DISINDAT        # CHECK MODE SELECT SWITCH AND DIDFLG.
                CS      BIT7
                MASK    IMODES33
                TS      IMODES33        # ALTERNATE ALTITUDE RATE WITH ALTITUDE.
                CS      BIT2
                EXTEND
                WAND    CHAN14
                CCS     ALTBITS         # = -1 IF OLD ALT. DATA TO BE EXTRAPOLATED.
                TCF     +4
                TCF     +3
                TCF     OLDDATA
                TS      ALTBITS         # SET ALTBITS FROM -0 TO +0.
                CS      ONE
                DXCH    ALTBITS         # SET ALTBITS = -1 FOR SWITCH USE NEXT PASS.
                DXCH    ALTSAVE
                CA      BIT10           # NEW ALTITUDE EXTRAPOLATION WITH ALTRATE.
                XCH     Q
                LXCH    7               # ZL
                CA      DT
                EXTEND
                DV      Q               # RESCALE DT*2(-14) TO *2(-9) TIME IN CS.
                EXTEND
                MP      ARTOA2          # .0021322 *2(+8)
                TCF     OLDDATA +1      # RATE APPLIES FOR DT CS.

ZDATA2          DXCH    ALTSAVE
                TCF     NEWDATA
OLDDATA         CA      ARTOA           # RATE APPLIES FOR .5 SEC. (4X/SEC. CYCLE)
                EXTEND
                MP      ALTRATE         # EXTRAPOLATE WITH ALTITUDE RATE.
                DDOUBL
                AD      ALTSAVE +1
                TS      ALTSAVE +1
                CAF     ZERO
                ADS     ALTSAVE
                CAF     POSMAX          # FORCE SIGN AGREEMENT ASSUMING A
                AD      ONE             # NON-NEGATIVE ALTSAVE.
                AD      ALTSAVE +1      # IF ALTSAVE IS NEGATIVE, ZERO ALTSAVE
                TS      ALTSAVE +1      # AND ALTSAVE +1 AT ZERODATA.
## Page 893
                CAF     ZERO
                AD      POSMAX
                AD      ALTSAVE
                TS      ALTSAVE         # POSSIBLY SKIP TO NEWDATA.
                TCF     ZERODATA
NEWDATA         CCS     ALTSAVE +1
                TCF     +4
                TCF     +3
                CAF     ZERO            # SET NEGATIVE ALTSAVE +1 TO +0.
                TS      ALTSAVE +1
                CCS     ALTSAVE         # PROVIDE A 15 BIT UNSIGNED OUTPUT.
                CAF     BIT15           # THE HI-ORDER PART IS +1 OR +0.
                AD      ALTSAVE +1
                TCF     DATAOUT         # DISPATCH UNSIGNED BITS TO ALTM REG.
DISINDAT        EXTEND
                QXCH    LADQSAVE        # SAVE RETURN TO ALTROUT +1 OR ALTOUT +1
                CS      FLAGWRD1        # YES.  CHECK STATUS OF DIDFLAG.
                MASK    DIDFLBIT
                EXTEND
                BZF     SPEEDRUN        # SET.  PERFORM DATA DISPLAY SEQUENCE.
                CS      FLAGWRD1        # RESET.  PERFORM INITIALIZATION FUNCTIONS.
                MASK    DIDFLBIT
                ADS     FLAGWRD1        # SET DIDFLAG.
                CS      BIT7
                MASK    IMODES33        # TO DISPLAY ALTRATE FIRST AND ALT. SECOND
                TS      IMODES33
                CS      FLAGWRD0        # ARE WE IN DESCENT TRAJECTORY?
                MASK    R10FLBIT
                EXTEND
                BZF     TASKOVER        # NO
                CAF     BIT8            # YES.
                EXTEND
                WOR     CHAN12          # SET DISPLAY INERTIAL DATA OUTBIT.
                CAF     ZERO
                TS      TRAKLATV        # LATERAL VELOCITY MONITOR FLAG
                TS      TRAKFWDV        # FORWARD VELOCITY MONITOR FLAG
                TS      LATVMETR        # LATVEL MONITOR METER
                TS      FORVMETR        # FORVEL MONITOR METER
                CAF     BIT4
                TC      TWIDDLE
                ADRES   INTLZE
                TCF     TASKOVER
INTLZE          CAF     BIT2
                EXTEND
                WOR     CHAN12          # ENABLE RR ERROR COUNTER.
## Page 894
                CS      IMODES33
                MASK    BIT8
                ADS     IMODES33        # SET INERTIAL DATA FLAG.
                TCF     TASKOVER

SPEEDRUN        CS      PIPTIME +1      # UPDATE THE VELOCITY VECTOR
                AD      TIME1           # COMPUTE T - TN
                AD      HALF            # CORRECT FOR POSSIBLE OVERFLOW OF TIME1.
                AD      HALF
                XCH     DT              # SAVE FOR LATER USE
                CA      1SEC
                TS      ITEMP5          # INITIALIZE FOR DIVISION LATER
                EXTEND
                DCA     GDT/2           # COMPUTE THE X-COMPONENT OF VELOCITY.
                DDOUBL
                DDOUBL
                EXTEND
                MP      DT
                EXTEND
                DV      ITEMP5
                XCH     VVECT           # VVECT = G(T-TN) M/CS *2(-5)
                EXTEND
                DCA     V               # M/CS *2(-7)
                DDOUBL                  # RESCALE TO 2(-5)
                DDOUBL
                ADS     VVECT           # VVECT = VN + G(T-TN) M/CS *2(-5)
                CA      PIPAX           # DELV CM/SEC *2(-14)
                AD      PIPATMPX        # IN CASE PIPAX HAS BEEN ZEROED
                EXTEND
                MP      KPIP1(5)        # DELV M/CS *2(-5)
                ADS     VVECT           # VVECT = VN + DELV + GN(T-TN) M/CS *2(-5)
                EXTEND
                DCA     GDT/2 +2        # COMPUTE THE Y-COMPONENT OF VELOCITY.
                DDOUBL
                DDOUBL
                EXTEND
                MP      DT
                EXTEND
                DV      ITEMP5
                XCH     VVECT +1
                EXTEND
                DCA     V +2
                DDOUBL
                DDOUBL
                ADS     VVECT +1
                CA      PIPAY
                AD      PIPATMPY
                EXTEND
                MP      KPIP1(5)
                ADS     VVECT +1
## Page 895
                EXTEND
                DCA     GDT/2 +4        # COMPUTE THE Z-COMPONENT OF VELOCITY.
                DDOUBL
                DDOUBL
                EXTEND
                MP      DT
                EXTEND
                DV      ITEMP5
                XCH     VVECT +2
                EXTEND
                DCA     V +4
                DDOUBL
                DDOUBL
                ADS     VVECT +2
                CA      PIPAZ
                AD      PIPATMPZ
                EXTEND
                MP      KPIP1(5)
                ADS     VVECT +2

                CAF     BIT3            # PAUSE 40 MS TO LET OTHER RUPTS IN.
                TC      VARDELAY

                CA      DELVS           # HI X OF VELOCITY CORRECTION TERM.
                AD      VVECT           # HI X OF UPDATED VELOCITY VECTOR.
                TS      ITEMP1          # = VX - DVX M/CS *2(-5).
                CA      DELVS +2        #    Y
                AD      VVECT +1        #    Y
                TS      ITEMP2          # = VY - DVY M/CS *2(-5).
                CA      DELVS +4        #    Z
                AD      VVECT +2        #    Z
                TS      ITEMP3          # = VZ - DVZ M/CS *2(-5).
                CA      ITEMP1          # COMPUTE VHY, VELOCITY DIRECTED ALONG THE
                EXTEND                  # Y-COORDINATE.
                MP      UHYP            # HI X OF CROSS-RANGE HALF-UNIT VECTOR.
                XCH     RUPTREG1
                CA      ITEMP2
## Page 896
                EXTEND
                MP      UHYP +2         # Y
                ADS     RUPTREG1        # ACCUMULATE PARTIAL PRODUCTS.
                CA      ITEMP3
                EXTEND
                MP      UHYP +4         # Z
                ADS     RUPTREG1
                CA      RUPTREG1
                DOUBLE
                XCH     VHY             # VHY=VMP.UHYP M/CS*2(-5).
                CA      ITEMP1          # NOW COMPUTE VHZ, VELOCITY DIRECTED ALONG
                EXTEND                  # THE Z-COORDINATE.
                MP      UHZP            # HI X OF DOWN-RANGE HALF-UNIT VECTOR.
                XCH     RUPTREG1
                CA      ITEMP2
                EXTEND
                MP      UHZP +2         # Y
                ADS     RUPTREG1        # ACCUMULATE PARTIAL PRODUCTS.
                CA      ITEMP3
                EXTEND
                MP      UHZP +4         # Z
                ADS     RUPTREG1
                CA      RUPTREG1
                DOUBLE
                XCH     VHZ             # VHZ = VMP.UHZP M/CS*2(-5).
GET22/32        CAF     EBANK6          # GET SIN(AOG),COS(AOG) FROM GPMATRIX.
                TS      EBANK
                EBANK=  M22
                CA      M22
                TS      ITEMP3
                CA      M32
                TS      ITEMP4
                CAF     EBANK7
                TS      EBANK
                EBANK=  UNIT/R/
LADFWDV         CA      ITEMP4          # COMPUTE LATERAL AND FORWARD VELOCITIES.
                EXTEND
                MP      VHY
                XCH     RUPTREG1
                CA      ITEMP3
                EXTEND
                MP      VHZ
                ADS     RUPTREG1        # = VHY(COS)AOG+VHZ(SIN)AOG M/CS *2(-5)
                CA      VELCONV         # CONVERT LATERAL VELOCITY TO BIT UNITS.
                EXTEND
                MP      RUPTREG1
                DDOUBL
                XCH     LATVEL          # LATERAL VELOCITY IN BIT UNITS *2(-14).
                CA      ITEMP4          # COMPUTE FORWARD VELOCITY.
                EXTEND
## Page 897
                MP      VHZ
                XCH     RUPTREG1
                CA      ITEMP3
                EXTEND
                MP      VHY
                CS      A
                ADS     RUPTREG1        # =VHZ(COS)AOG-VHY(SIN)AOG M/CS *2(-5).
                CA      VELCONV         # CONVERT FORWARD VELOCITY TO BIT UNITS.
                EXTEND
                MP      RUPTREG1
                DDOUBL
                XCH     FORVEL          # FORWARD VELOCITY IN BIT UNITS *2(-14).

                CAF     BIT6
                EXTEND                  # WISHETH THE ASTRONAUT THE ANALOG
                RAND    CHAN30          # DISPLAYS?  I.E.,
                CCS     A               # IS THE MODE SELECT SWITCH IN PGNCS?
                TCF     DISPRSET        # NO.  ASTRONAUT REQUESTS NO INERTIAL DATA

                CS      FLAGWRD0        # ARE WE IN DESCENT TRAJECTORY?
                MASK    R10FLBIT
                CCS     A
                TCF     +2              # YES.
                TC      LADQSAVE        # NO.

                CS      MAXVBITS        # ACC.=-199.9989 FT./SEC.
                TS      ITEMP6          # -547 BIT UNITS (OCTAL) AT 0.5571 FPS/BIT

                CAF     ONE             # LOOP TWICE.
VMONITOR        TS      ITEMP5          # FORWARD AND LATERAL VELOCITY LANDING
                INDEX   ITEMP5          #       ANALOG DISPLAYS MONITOR.
                CCS     LATVEL
                TCF     +4
                TCF     LVLIMITS
                TCF     +8D
                TCF     LVLIMITS
                INDEX   ITEMP5
                CS      LATVEL
                AD      MAXVBITS        # +199.9989 FT./SEC.
                EXTEND
                BZMF    CHKLASTY
                TCF     LVLIMITS
                INDEX   ITEMP5
                CA      LATVEL
                AD      MAXVBITS
                EXTEND
                BZMF    +2
                TCF     LVLIMITS
CHKLASTY        INDEX   ITEMP5
                CCS     LATVMETR
                TCF     +4
                TCF     LASTOK
                TCF     +7
                TCF     LASTOK
                INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    LASTPOSY +5
                TCF     +5
                INDEX   ITEMP5
                CS      LATVEL
                EXTEND
## Page 898
                BZMF    LASTNEGY +4
LASTOK          INDEX   ITEMP5
                CCS     TRAKLATV
                TCF     LASTPOSY
                TCF     +2
                TCF     LASTNEGY
                INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    NEGVMAXY
                TCF     POSVMAXY
LASTPOSY        INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    +2
                TCF     POSVMAXY
                CS      MAXVBITS
                TCF     ZEROLSTY
POSVMAXY        INDEX   ITEMP5
                CS      LATVMETR
                AD      MAXVBITS
                INDEX   ITEMP5
                XCH     RUPTREG3
                CAF     ONE
                TCF     ZEROLSTY +3
LASTNEGY        INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    NEGVMAXY
                CA      MAXVBITS
                TCF     ZEROLSTY
NEGVMAXY        INDEX   ITEMP5
                CA      LATVMETR
                AD      MAXVBITS
                COM
                INDEX   ITEMP5
                XCH     RUPTREG3
                CS      ONE
                TCF     ZEROLSTY +3
LVLIMITS        INDEX   ITEMP5
                CCS     TRAKLATV
                TCF     LATVPOS
                TCF     +2
                TCF     LATVNEG
                INDEX   ITEMP5
                CS      LATVMETR
                EXTEND
                BZMF    +2
                TCF     NEGLMLV
                INDEX   ITEMP5
## Page 899
                CS      LATVEL
                EXTEND
                BZMF    LVMINLM
                AD      ITEMP6
                INDEX   ITEMP5
                AD      LATVMETR
                EXTEND
                BZMF    LVMINLM
                INDEX   ITEMP5
                AD      LATVEL
                EXTEND
                INDEX   ITEMP5
                SU      LATVMETR
                TCF     ZEROLSTY
LATVPOS         INDEX   ITEMP5
                CS      LATVEL
                EXTEND
                BZMF    LVMINLM
                TCF     +5
LATVNEG         INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    LVMINLM
                INDEX   ITEMP5
                CS      LATVMETR
                TCF     ZEROLSTY
NEGLMLV         INDEX   ITEMP5
                CA      LATVEL
                EXTEND
                BZMF    LVMINLM
                CA      MAXVBITS
                INDEX   ITEMP5
                AD      LATVMETR
                COM
                INDEX   ITEMP5
                AD      LATVEL
                EXTEND
                BZMF    LVMINLM
                EXTEND
                INDEX   ITEMP5
                SU      LATVEL
                INDEX   ITEMP5
                AD      LATVMETR
                COM
                TCF     ZEROLSTY
LVMINLM         INDEX   ITEMP5
                CS      LATVMETR
                INDEX   ITEMP5
                AD      LATVEL
ZEROLSTY        INDEX   ITEMP5
## Page 900
                XCH     RUPTREG3
                CAF     ZERO
                INDEX   ITEMP5
                TS      TRAKLATV
                INDEX   ITEMP5
                CA      RUPTREG3
                AD      NEG0            # AVOIDS +0 DINC HARDWARE MALFUNCTION
                INDEX   ITEMP5
                TS      CDUTCMD
                INDEX   ITEMP5
                CA      RUPTREG3
                INDEX   ITEMP5
                ADS     LATVMETR
                CCS     ITEMP5          # FIRST MONITOR FORWARD THEN LATERAL VEL.
                TCF     VMONITOR

                CAF     BIT2            # CHECK TO SEE IF RR ERROR COUNTERS
                EXTEND                  # ARE ENABLED.
                RAND    CHAN12
                CCS     A               # IF NOT.
                TCF     +2
                TCF     DISPRSET        # RE-INITIALIZE LANDING ANALOG DISPLAYS

                CAF     BITSET          # DRIVE THE X-POINTER DISPLAY.
                EXTEND
                WOR     CHAN14
                TC      LADQSAVE        # GO TO ALTROUT +1 OR TO ALTOUT +1
ZERODATA        CAF     ZERO            # ZERO ALTSAVE AND ALTSAVE +1 - - -
                TS      L               #       NO NEGATIVE ALTITUDES ALLOWED.
                TCF     ZDATA2

# ************************************************************************

DISPRSET        CS      FLAGWRD0        # ARE WE IN DESCENT TRAJECTORY?
                MASK    R10FLBIT
                EXTEND
                BZF     ABORTON         # NO.
                CAF     BIT8            # YES.
                MASK    IMODES33        # CHECK IF INERTIAL DATA JUST DISPLAYED.
                CCS     A
                CAF     BIT2            # YES. DISABLE RR ERROR COUNTER
                AD      BIT8            # NO.  REMOVE DISPLAY INERTIAL DATA
                COM
                EXTEND
                WAND    CHAN12
ABORTON         CS      BITS8/7         # RESET INERTIAL DATA, INTERLEAVE FLAGS.
                MASK    IMODES33
                TS      IMODES33
                CS      DIDFLBIT
                MASK    FLAGWRD1
                TS      FLAGWRD1        # RESET DIDFLAG.
                TCF     TASKOVER

# ************************************************************************

BITS8/7         OCT     00300           # INERTIAL DATA AND INTERLEAVE FLAGS.
BITSET          =       PRIO6

# ************************************************************************

## Page 901
## There is no source code on the original program listing.

