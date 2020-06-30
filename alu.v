// DESIGN SPECIFIC
`define ALU_BUS_WITH 		16
`define ALU_AMM_ADDR_WITH 	8
`define ALU_AMM_DATA_WITH	8   

/**

== Input packets ==

Header beat
+-----------------+--------------+---------------+------------------+
| reserved[15:12] | opcode[11:8] | reserved[7:6] | nof_operands[5:0]|
+-----------------+--------------+---------------+------------------+

Payload beat
+-----------------+----------+----------------------+
| reserved[15:10] | mod[9:8] | operands/address[7:0]|
+-----------------+----------+----------------------+

== Output packets ==

Header beat

+----------------+----------+-------------+
| reserved[15:5] | error[4] | opcode[3:0] |
+----------------+----------+-------------+

Payload beat

+-----------------+--------------+
| reserved[15:12] | result[11:0] |
+-----------------+--------------+

*/
module alu(
	 // Output interface
    output reg [`ALU_BUS_WITH - 1:0] data_out,
	 output reg						         valid_out,
	 output reg    							cmd_out,

	 //Input interface
	 input [`ALU_BUS_WITH - 1:0] data_in,
	 input 							  valid_in,
	 input 							  cmd_in,
	 
	 // AMM interface
	 output reg		    					     amm_read,
	 output reg[`ALU_AMM_ADDR_WITH - 1:0] amm_address,
	 input [`ALU_AMM_DATA_WITH - 1:0]     amm_readdata,
	 input 									     amm_waitrequest,
	 input [1:0] 						    	  amm_response,
	 
	 
	 //clock and reset interface
	 input clk,
	 input rst_n
    );
	 
	 `define reset                   'h00  
	 `define header                  'h10
	 `define payload                 'h20
	 `define adresare                'h30
	 `define operatii                'h40
	 `define amm                     'h50
	 `define header_out              'h60
	 `define payload_out             'h70
	 `define header_notok            'h80
	 `define payload_notok           'h90
	 
	 reg [3:0] opcode;
	 reg [5:0] nof_operands;

	 reg [5:0] contor;
	 reg [5:0] contor_next;
	 
	 reg [1:0] mod [62:0];
	 reg [1:0] mod_next;
	 reg [7:0] operand_or_address [62:0];
	 reg [7:0] operand_or_address_next;
	 
	 reg bitsemn;
	 reg [6:0] c;
	 
	 reg [11:0] rez;
	 reg [11:0] rez_next;
	 reg [11:0] rez_and;
	 
	 reg [15:0] state = `reset, state_next;
	 
	 `define ADD                     0
	 `define AND                     1
	 `define OR                      2
	 `define XOR                     3
	 `define NOT                     4
	 `define INC                     5
	 `define DEC                     6
	 `define NEG                     7
	 `define SHR                     8
	 `define SHL                     9
	
	// TODO: Implement Not-so-simple ALU
	always @(posedge clk) begin

    if(rst_n) begin
        state <= state_next;
		  mod[contor] <= mod_next;
		  operand_or_address[contor] <= operand_or_address_next;
		  contor <= contor_next;
		  
		  rez <= rez_next;
    end
	 else
		state <= `reset;
   end
	
	always @(*) begin
		//state_next=`reset;
		valid_out=0;
		cmd_out=0;
		data_out=0;
		
		case(state)
		
			`reset: begin
				state_next=`header;
				contor_next=0;
				rez_next=0;
			end
///////////////////////////////decodeaza headerul (din data_in)/////////////////////////////////////////////////////////////////////////////////////////////////			
			`header: begin
				if (valid_in==1 && cmd_in==1) begin //verificare cerinte de decodare
						opcode=data_in[11:8];
						nof_operands=data_in[5:0];
						//rez_next=rez;
						
						state_next=`payload;
				end
				else 
					state_next=`header; //asigura continuitate intre stari
			end
///////////////////////////////decodeaza headerul (din data_in)//////////////////////////////////////////////////////////

///////////////////////////////decodeaza payloadul(din data_in)//////////////////////////////////////////////////////////			
			`payload: begin
				if (valid_in==1 && cmd_in==0) begin //verificare cerinte de decodare
					mod_next=data_in[9:8]; 
					operand_or_address_next=data_in[7:0];
				   contor_next=contor+1;	
					//rez_next=rez;
					
					if (contor == nof_operands-1) begin
						contor_next=0;
						rez_and=operand_or_address[contor_next];
						state_next=`adresare;
					end
					else 
						state_next=`payload;
				end
				else
					state_next=`header_notok;
			end
///////////////////////////////decodeaza payloadul(din data_in)//////////////////////////////////////////////////////////	
			
//mod_next si operand_or_address_next vor fi reinitializati in fiecare stare pentru a pastra valorile anterioare
//deoarece mod[contor] si operand_or_address[contor] vor fi reactualizati la fiecare clk

///////////////////////////////alege stari in functie de modul de adresare//////////////////////////////////////////////////////////	
			`adresare: begin
				mod_next=mod[contor];
				operand_or_address_next=operand_or_address[contor];
				//contor_next=contor;
				//rez_next=rez;
				
				case(mod[contor])
					2'b00: state_next=`operatii;
					2'b01: state_next=`amm;
				endcase
			end
///////////////////////////////alege stari in functie de modul de adresare////////////////////////////////////////////////////////

//////////////////////////////face operatii in ambele cazuri de adresa ///////////////////////////////////////////////////////			
			`operatii: begin
				mod_next=mod[contor];
				operand_or_address_next=operand_or_address[contor];
				contor_next=contor+1;
				
				case(opcode)
					`ADD: rez_next=rez + operand_or_address_next;
					`AND: begin
						rez_next=rez_and & operand_or_address_next;
						rez_and=rez_next;
					end
					`OR:  rez_next=rez | operand_or_address_next;
					`XOR: rez_next=rez^operand_or_address_next;
					`NOT: begin
						if (nof_operands!=1)
							state_next=`header_notok;
						else
							rez_next=~operand_or_address_next;
					end
					`INC: begin
						if (nof_operands!=1)
							state_next=`header_notok;
						else
							rez_next=operand_or_address_next + 'd1;
					end
					`DEC: begin
						if (nof_operands!=1)
							state_next=`header_notok;
						else
							rez_next=operand_or_address_next - 'd1;
					end
					`NEG: begin
						if (nof_operands!=1)
							state_next=`header_notok;
						else 
							rez_next=~operand_or_address_next+1;
					end
					`SHR: begin
						if (nof_operands!=2)
							state_next=`header_notok;
						else
							rez_next=operand_or_address[0] >> operand_or_address[1];
					end
					`SHL: begin
						if (nof_operands!=2)
							state_next=`header_notok;
						else
							rez_next=operand_or_address[1] >> operand_or_address[0];
					end
				endcase
				
				if (contor == nof_operands-1) 
					state_next=`header_out;
				else 
					state_next=`adresare;
			end
//////////////////////////////face operatii in ambele cazuri de adresa ///////////////////////////////////////////////////////
	
///////////////////////////////aduce din memorie operandul///////////////////////////////////////////////////////////////////////////////////////////	
			`amm: begin    // starea coresp clk 3
				if (amm_waitrequest == 1) begin
					amm_address[7:0]=operand_or_address[contor];
					amm_read=1;
					
					mod_next=mod[contor];
					operand_or_address_next=operand_or_address[contor];
					//contor_next=contor;
					
					state_next=`amm + 'd1;
				end
				else
					state_next=`amm;
			end
			
			`amm + 'd1: begin //starea coresp clk 5
				if (amm_waitrequest == 1) begin
					mod_next=mod[contor];
					operand_or_address_next=operand_or_address[contor];
					//contor_next=contor;
					
					state_next=`amm + 'd2;
				end
				else 
					state_next=`header_notok;
			end
			
			`amm + 'd2:  begin //starea coresp clk 7
				if (amm_waitrequest == 1) begin
					mod_next=mod[contor];
					operand_or_address_next=operand_or_address[contor];
					//contor_next=contor;
					
					state_next=`amm + 'd3;
				end
				else 
					//rez='hBAD;
				   state_next=`header_notok;
			end
			
			`amm + 'd3: begin  //starea coresp clk 9
				if (amm_waitrequest == 0) begin
					operand_or_address_next=amm_readdata;
					amm_read=0;
					
					mod_next=mod[contor];
					//contor_next=contor;
				
				//	DECODEERROR
				if (amm_readdata > 'h0F || amm_readdata < 'h30 || amm_readdata > 'h7F || amm_readdata < 'hA0 || amm_readdata > 'hFF)
					state_next=`header_notok;
					
				case(amm_response)
					2'b00: state_next=`amm + 'd4; //OK
					2'b01: state_next=`header_notok;             //RESERVED
					2'b10: state_next=`header_notok;             //SLAVEERROR
					2'b11: state_next=`header_notok;             //DECODEERROR
				endcase
				end
				else
					state_next=`header_notok;
			end
			
			`amm + 'd4: begin  //starea coresp clk11
				amm_read=0;
				
				mod_next=mod[contor];
				operand_or_address_next=operand_or_address[contor];
				//contor_next=contor;
					
				state_next=`operatii;
			end
///////////////////////////////aduce din memorie operandul////////////////////////////////////////////////////////////////////

///////////////////////////////trimite headerul////////////////////////////////////////////////////////////////////
			`header_out: begin
				valid_out=1;
				cmd_out=1;
				data_out[3:0]=opcode;
				//rez_next=rez;
				
				mod_next=mod[contor];
				operand_or_address_next=operand_or_address[contor];
				
				if (rez=='hBAD)
					data_out[4]=1;
				else
					data_out[4]=0;
					
				state_next=`payload_out;
			end
//////////////////////////////trimite headerul////////////////////////////////////////////////////////////////////
			
//////////////////////////////trimite payloadul////////////////////////////////////////////////////////////////////
			`payload_out: begin
				valid_out=1;
				cmd_out=0;
				data_out[11:0]=rez;
				
				state_next=`reset;
			end
//////////////////////////////trimite payloadul////////////////////////////////////////////////////////////////////
		
//////////////////////////////caz de trimitere header eroare////////////////////////////////////////////////////////////////////		
			`header_notok: begin
				valid_out=1;
				cmd_out=1;
				data_out[3:0]=opcode;
				rez_next='hBAD;
				
				if (rez_next=='hBAD)
					data_out[4]=1;
				else
					data_out[4]=0;
				
				state_next=`payload_notok;
			end
////////////////////////////caz de trimitere header eroare/////////////////////////////////////////////////////////////

////////////////////////////caz de trimitere payload eroare/////////////////////////////////////////////////////////////		
			`payload_notok: begin
				valid_out=1;
				cmd_out=0;
				data_out[11:0]=rez;
				
				state_next=`reset;
			end
////////////////////////////caz de trimitere header eroare/////////////////////////////////////////////////////////////
		
	   endcase
	end
endmodule