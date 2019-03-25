# BCD-Calculator
RPN calculator for unlimited-precision unsigned integers, represented in Binary Coded Decimal. 

 Reverse Polish notation (RPN) is a mathematical notation in which every operator follows all of its 
 operands, for example "3 + 4 =" would be presented as "3 4 +". For simplicity, each operator or number
 will appear on a separate line of input. For example, to enter a number 73 and then 80, and then add them, 
 the user should type:7380+Note that "73" will stored as 01110011, the hexadecimal representation of 
 the actual bits is 0x73, and "80" will stored as 10000000, the hexadecimal representation of the actual bits is 0x80.
 
 ## Implementation of Unlimited Precision
 In order to support unlimited precision, each operand in the operand stack stores a linked list (of bytes) for each operand.
  The operand stack is implemented as an array of pointers - each pointing to the first element of 
  the list representing the number,
  or null (a null pointer has value 0). The operand stack size is 5.
  
  ## Supported operations
  * Quit (q)
  
  * Addition (unsigned) (+)
  
  * Pop-and-print (p)
    
  * Duplicate (d)
    
  * Shift left (l)
  
      The '+' and 'l' operators each get 2 operands, and provide one result. 
    The "duplicate" operator takes one operand and provides two results - duplicates of its input operand.
    Pop-and-print takes one operand, and provides no result. It just prints the value of the operand to the standard output
    in decimal, as ASCII characters, 
    of course (e.g. BCD value of 00100011 in memory will be printed as '23'). 'p' print the prefix ">>", no ">>calc:"
    if we choose 'l' , if k is greater than 99, print an error "Error: exponent too large", and abort the operation.
    Otherwise, do the following computation (removing the 2 elements from the stack, and pushing the result onto the stack):
    computes (n * 2^k).
    
    ## Run example

```
calc: 9     ; user inputs a number
calc: 1      ; user inputs another number
calc: d      ; user enters "duplicate" operator
calc: p      ; user enters pop-and-print-operator
1
calc: +      ; user enters "addition" operator, 10 is in top of (and is the sole element in) stack right after
calc: d
calc: p
10
calc: 23      ; user enters another number 23
calc: +
calc: d
calc: p
33            ; the sum
calc: +
Error: Insufficient Number of Arguments on Stack
calc: q      ; Quit calculator
8      ; Number of operations performed
