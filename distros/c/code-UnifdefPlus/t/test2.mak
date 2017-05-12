#6.6:should simplify (visible) 
ifeq ($(and ${VAR1},${VAR2},${FOO}),y)
# 6.6 (V)
endif


# unifdef+ test for makefiles
# with -D FOO -D D1=1 -D D2=1 -DX=x -U BAR -U U1 -D E= -I t\test2.mak


#do not simplify (neither expression resolved):
ifeq 'xxx' 'xxx'
# 1.1 (V)
else
# 1.1 (V)
endif

#do not simplify (neither expression resolved):
ifeq "xxx" 'xxx'
# 1.2 (V)
else
# 1.2 (V)
endif

#do not simplify (neither expression resolved):
ifeq (xxx,xxx)
# 1.3 (V)
else
# 1.3 (V)
endif

#do not simplify (neither expression resolved):
ifeq (xxx,xyy)
# 1.4 (V)
else
# 1.4 (V)
endif


# simplify (FOO defined)
ifdef FOO
#1.5 (V)
else
#1.5 (I)
endif

# do not simplify (BAR unknown)
ifdef BAR
#1.6 (V)
else
#1.6 (V)
endif

# simplify (U1 undefined)
ifdef U1
#1.7 (I)
else
#1.7 (V)
endif

# simplify (E is defined, but empty...)
ifdef E
#1.8 (V)
else
#1.8 (I)
endif

# simplify (FOO defined)
ifndef FOO
#1.9 (I)
else
#1.9 (V)
endif

# do not simplify (VAR1 unknown)
ifndef VAR1
#1.10 (V)
else
#1.10 (V)
endif

# simplify (U1 undefined)
ifndef U1
#1.11 (V)
else
#1.11 (I)
endif

# simplify (E is defined, but empty...)
ifndef E
#1.12 (I)
else
#1.12 (V)
endif



# PART 2: with variables:

#simplify:
ifeq ($(FOO),y)
# 2.1 (V)
else
# 2.1 (I)
endif

#simplify:
ifeq ($(FOO),n)
# 2.2 (I)
else
# 2.2 (V)
endif

#simplify:
ifeq "${FOO}" "y"
# 2.3 (V)
else
# 2.3 (I)
endif

#simplify:
ifeq '$(FOO)' 'y'
# 2.4 (V)
else
# 2.4 (I)
endif

#simplify:
ifeq "y" '$(FOO)'
# 2.5 (V)
else
# 2.5 (I)
endif

#simplify:
ifeq 'y' "${FOO}"
# 2.6 (V)
else
# 2.6 (I)
endif

#simplify:
ifeq 'x' "$X"
# 2.6 (V)
else
# 2.6 (I)
endif

#do not simplify:
ifeq '$(VAR1)$X' "${VAR2}"
# 2.6 (V)
else
# 2.6 (V)
endif


# PART3: catination:

#simplify:
ifeq '$X1' "x1"
# 3.1 (V)
else
# 3.1 (I)
endif

# should not simplify -- $D is unknown...
ifeq '$X$D1' "x1"
# 3.2 (V)
else
# 3.2 (V)
endif

#simplify:
ifeq '$X1' "x$(D1)"
# 3.3 (V)
else
# 3.3 (I)
endif

#do not simplify:
ifeq 'abc$(VAR1)$(FOO)' "a$(VAR2)"
# 3.4 (V)
else
# 3.4 (V)
endif

#do not simplify:
ifeq 'a$(VAR1)$(FOO)' "abc${VAR2}"
# 3.5 (V)
else
# 3.5 (V)
endif

#simplify (cannot match due to prefix):
ifeq 'a$(VAR1)$X' "bc${VAR2}"
# 3.6 (I) - cannot possibly match
else
# 3.6 (V)
endif

# PART 4: else clauses:

# should simplify (2,3,4 visible)
ifeq 'a$(VAR1)$X' "bc${VAR2}"
# 4.1 (I1) - cannot possibly match
else ifdef VAR1
# 4.1 (v2)
else ifeq ($Y,x)
# 4.1 (V3)
else ifeq ($(D1),1)
# 4.1 (V4)
else ifeq ($(D1),2)
# 4.1 (I5)
else
# 4.1 (I6)
endif

# should simplify (3 visible)
ifeq '$(D1)' "$(D2)"
# 4.2 (I1)
else ifeq ($(D1),2)
# 4.2 (I2)
else ifeq ($(D1),1)
# 4.2 (V3)
else ifeq ($D1,2)
# 4.2 (I4)
else
# 4.2 (I5)
endif

# should simplify (2,3 visible)
ifeq '$(D1)' "$(D2)"
# 4.8 (I1)
else ifeq ($(D1),$(SSS))
# 4.8 (V2)
else
# 4.8 (V3)
endif

# should simplify (1,2,4 visible)
ifdef VAR1
# 4.9 (V1)
else ifndef VAR2
# 4.9 (V2)
else ifndef FOO
# 4.9 (I3)
else
# 4.9 (V4)
endif


# PART 5: functions (or)

#5.1: should simplify 
ifeq ($(or $(FOO),),y)
# 5.1 (V)
endif

#5.2: should simplify 
ifeq ($(or ,$(FOO)),y)
# 5.2 (V)
endif

#5.3: should simplify 
ifeq ($(or ${D1},${FOO}),y)
# 5.3 (I)
else ifeq ($(or ${D1},${FOO}),1)
# 5.3 (V)
endif

#5.4: should simplify 
ifeq ($(or ,,${FOO}),y)
# 5.4 (V)
endif

#5.5: should simplify  
ifeq ($(or ,,${BAR}),)
# 5.5 (V)
endif

#5.6: should simplify (visible, but ${BAR} removed as its undefined) 
ifeq ($(or ${VAR1},${VAR2},${BAR}),y)
# 5.6 (V)
endif


# PART 6: functions (and)

#6.1: should simplify (not visible) 
ifeq ($(and ${FOO},${BAR}),y)
# 6.1 (I)
endif

#6.2:should simplify (not visible) 
ifeq ($(and ${BAR},${FOO}),y)
# 6.2 (I)
endif

#6.3:should simplify (visible) 
ifeq ($(and ${D1},${D2}),1)
# 6.3 (I)
else ifeq ($(and ${D1},${D2}),2)
# 6.3 (V)
endif

#6.4:should simplify (visible) 
ifeq ($(and ${D1},${D2},${FOO}),y)
# 6.4 (V)
endif

#6.5:should simplify (not visible) 
ifeq ($(and ${D1},${FOO}),1)
# 6.5 (I)
endif

#6.6:should simplify (visible) 
ifeq ($(and ${VAR1},${VAR2},${FOO}),y)
# 6.6 (V)
endif
