# ALU
The ALU received data from an input source which tells the module the number of future operands and the operation that needs to pe implemented. 

The content of an operand can be found at a certain address - I have used an AMM (Avalon Memory-Mapped) interface for the extraction. Communication between the ALU and the memory module is based on a master-slave configuration. 

The operations that can be performed are both mathematical and logical and are implemented with logical gates: ADD, AND, OR, XOR, NOT, INC, DEC, NEG, SHR, SHL. The mathematical operations available can be constructed with one or more logical operations.

I have used Verilog for coding and XilinX IDE to simulate the project and verify the functionality of the design.
