module calc_new(keyb_clk, keyb_data, clk, reset, first_out, sign_out, second_out, eq_out, res1_out, res2_out);
//arxikopoiiseis
input keyb_clk;
input keyb_data, clk, reset;
output reg [6:0] first_out, sign_out, second_out, eq_out, res1_out, res2_out;
parameter [2:0] WAIT_OPERAND1 = 3'b000;
parameter [2:0] WAIT_OPERAND2 = 3'b001;
parameter [2:0] WAIT_OPERATOR = 3'b010;
parameter [2:0] WAIT_EQ = 3'b011;
parameter [2:0] WAIT_F0 = 3'b100;
parameter [2:0] AFTER_F0 = 3'b101;

reg [5:0] keyb_clk_samples;
reg [10:0] keyb_data_reg;
reg [5:0] dec_key; //gia ton dec1
reg [6:0] dec_out;  //gia to seven segment display

reg [2:0] state, previous_state;
reg [5:0] operand1, operand2;
reg sub;
reg error;

wire signed [5:0] result; //prosimasmeno gia na bgazei kai ta arnitika apotelesmata


//assign keyb_clk = (!keyb_data_reg[0]) ? 1'b0 : 1'bz; //an keyb_data_reg[0] = 0 tote keyb_clk = 1 allios high z

always @ (posedge clk or posedge reset)
begin 
if (reset) 
keyb_clk_samples <= 6'b000000;
else 
 keyb_clk_samples <= {keyb_clk, keyb_clk_samples[5:1]}; //pare th nea timi tou keyb_clk kai enose tin me to upoloipo keyb_clk_samples
end

always @ (posedge clk or posedge reset)
begin 
if (reset)
keyb_data_reg <= 11'b11111111111;
else if (!keyb_data_reg[0]) 
keyb_data_reg <= 11'b11111111111; //exei teleiosei o arithmos kai arxikopoioume
else if (keyb_clk_samples == 6'b000111)
keyb_data_reg <= {keyb_data, keyb_data_reg[10:1]}; //olisthisi ton deigmaton sta deksia
end


//apokodikopoiitis
 always @(*) begin
        case (keyb_data_reg[8:1])
            8'h70: dec_key <= 6'b000000; // "0"
            8'h69: dec_key <= 6'b000001; // "1"
            8'h72: dec_key <= 6'b000010; // "2"
            8'h7A: dec_key <= 6'b000011; // "3"
            8'h6B: dec_key <= 6'b000100; // "4"
            8'h73: dec_key <= 6'b000101; // "5"
            8'h74: dec_key <= 6'b000110; // "6"
            8'h6C: dec_key <= 6'b000111; // "7"
            8'h75: dec_key <= 6'b001000; // "8"
            8'h7D: dec_key <= 6'b001001; // "9"
            default: dec_key <= 6'b100000; // agnosto pliktro - anathesi se -32
        endcase
    end
    

//eksodos seven segment display
 always @(*) begin
        case (dec_key)
            6'b000000: dec_out <= 7'b1000000; // "0"
            6'b000001: dec_out <= 7'b1111001; // "1"
            6'b000010: dec_out <= 7'b0100100; // "2"
            6'b000011: dec_out <= 7'b0110000; // "3"
            6'b000100: dec_out <= 7'b0011001; // "4"
            6'b000101: dec_out <= 7'b0010010; // "5"
            6'b000110: dec_out <= 7'b0000010; // "6"
            6'b000111: dec_out <= 7'b1111000; // "7"
            6'b001000: dec_out <= 7'b0000000; // "8"
            6'b001001: dec_out <= 7'b0010000; // "9"
            default: dec_out <= 7'b0000110; //"E"   
        endcase


end

//0 gia prosthesi 1 gia afairesi
assign result = operand1 + (operand2 ^ {6{sub}}) + sub;


always @(posedge clk or posedge reset)
 begin
   if (reset)
 begin
      state <= WAIT_OPERAND1;
      previous_state <= WAIT_OPERAND1;
//ola ta LED svista
      first_out <= 7'b1111111;
      sign_out <= 7'b1111111;
      second_out <= 7'b1111111;
      eq_out <= 7'b1111111;
      res1_out <= 7'b1111111;
      res2_out <= 7'b1111111;
//ta operands 0
      operand1 <= 6'b000000;
      operand2 <= 6'b000000;
   end 

//otan kleidosei i apokodikopoiimeni timi tou lifthentos scan kodikou
else if (!keyb_data_reg[0]) 
begin
      case (state)
         WAIT_OPERAND1: //an eimaste stin katastasi WAIT_OPERAND1
         begin
previous_state <= WAIT_OPERAND1; //apothikeuse sto previous state tin idia tin katastasi
//ta upoloipa LED svista
               sign_out <= 7'b1111111;
               second_out <= 7'b1111111;
               eq_out <= 7'b1111111;
               res1_out <= 7'b1111111;
               res2_out <= 7'b1111111;
            if (dec_key != 6'b100000) //an den exei patithei lathos pliktro
            begin
               operand1 <= dec_key; //pare tin 6biti apokodikopoiimeni timi gia tin praksi
               first_out <= dec_out; //vgale sto seven segment tou protou telesteou ton arithmo pou patithike
               state <= WAIT_F0; //pigaine stin katastasi WAIT_F0
               error <= 1'b0; //orise to error me 0
            end 
            
else //allios
            begin
               error <= 1'b1; //orise to error me 1
               first_out <= 7'b0000110; //vgale sto seven segment tou protou telesteou "E"
               state <= WAIT_F0; //pigaine stin katastasi WAIT_F0
            end
         end

         WAIT_OPERATOR: //an eimaste stin katastasi WAIT_OPERATOR
 begin
// ta upoloipa LED ektos tou protou telesteou svista
               second_out <= 7'b1111111;
               eq_out <= 7'b1111111;
               res1_out <= 7'b1111111;
               res2_out <= 7'b1111111;
               previous_state <= WAIT_OPERATOR; //apothikeuse sto previous state tin idia tin katastasi
               state <= WAIT_F0; //pigaine stin katastasi WAIT_F0
               
            if (keyb_data_reg[8:1] == 8'h79) //an o telestis einai "+"
begin
               
               sub <= 1'b0; //orise to sub iso me 0 gia toin praksi
               sign_out <= 7'b0001111; //vgale sto seven segment tou telesti to "+" 
               error <= 1'b0; //orise to error iso me 0
            end 

else if (keyb_data_reg[8:1] == 8'h7B) //an o telestis einai "-"
 begin
               sub <= 1'b1; //orise to sub iso me 1 gia tin praksi
               sign_out <= 7'b0111111; //vgale sto seven segment tou telesti to "+"
               error <= 1'b0; //orise to error iso me 0
            end 
else //an patithei lathos pliktro
 begin
               error <= 1'b1; //orise to error iso me 0
               sign_out <= 7'b0000110; //vgale sto seven segment tou telesti "E"
            end
            
         end
         WAIT_OPERAND2: //an eimaste stin katastasi WAIT_OPERAND2
begin
  previous_state <= WAIT_OPERAND2; //apothikeuse sto previous state tin idia tin katastasi
//ta upoloipa LED svista ektos tou protou telesteou kai tou telesti
               eq_out <= 7'b1111111;
               res1_out <= 7'b1111111;
               res2_out <= 7'b1111111;
            if (dec_key != 6'b100000)  //an den exei patithei lathos pliktro
begin
               operand2 <= dec_key; //pare tin 6biti apokodikopoiimeni timi gia tin praksi
               second_out <= dec_out; //vgale sto seven segment tou deuterou telesteou ton arithmo pou patithike
               state <= WAIT_F0;  //pigaine stin katastasi WAIT_F0
               error <= 1'b0; //orise to error me 0
            end
 else 
begin
               error <= 1'b1; //orise to error me 1
               second_out <= 7'b0000110; //vgale sto seven segment tou deuterou telesteou "E"
               state <= WAIT_F0;  //pigaine stin katastasi WAIT_F0
            end
         end
   
WAIT_EQ:  //an eimaste stin katastasi WAIT_EQ
begin
    if (keyb_data_reg[8:1] == 8'h55) //an to plikktro pou patithike einai to "="
    begin
        eq_out <= 7'b0110111; //vgale sto seven segment tou ison to "="
        previous_state <= WAIT_EQ; //apothikeuse sto previous state tin idia tin katastasi
        state <= WAIT_F0; //pigaine stin katastasi WAIT_F0
        error <= 1'b0; //orise to error me 0
         
       if (result < 0) //an to apotelesma tis praksis arnitiko
        begin
            res1_out <= 7'b0111111; //vgale sto seven segment tou protou aritmou tou apotelesmatos to "-"
            case (result)  //case gia to ti tha vgalei to seven segment tou deuterou arithmou tou apotelesmatos
                -6'd1: res2_out <= 7'b1111001; //"1"
                -6'd2: res2_out <= 7'b0100100; //"2" 
                -6'd3: res2_out <= 7'b0110000; //"3"
                -6'd4: res2_out <= 7'b0011001; //"4"
                -6'd5: res2_out <= 7'b0010010; //"5"
                -6'd6: res2_out <= 7'b0000010; //"6"
                -6'd7: res2_out <= 7'b1111000; //"7"
                -6'd8: res2_out <= 7'b0000000; //"8"
                -6'd9: res2_out <= 7'b0010000; //"9"
            endcase
        end 
        else if (result < 6'd10 && result >= 6'd0) // an to apotelesma einai apo 0 eos 9
        begin
            res1_out <= 7'b1111111; //o protos aritmos tou apotelesmatos svistos (monopsifio apotelesma)
            case (result)  //case gia to ti tha vgalei to seven segment tou deuterou arithmou tou apotelesmatos
                6'd0: res2_out <= 7'b1000000; //"0"
                6'd1: res2_out <= 7'b1111001; //"1"
                6'd2: res2_out <= 7'b0100100; //"2"
                6'd3: res2_out <= 7'b0110000; //"3"
                6'd4: res2_out <= 7'b0011001; //"4"
                6'd5: res2_out <= 7'b0010010; //"5"
                6'd6: res2_out <= 7'b0000010; //"6"
                6'd7: res2_out <= 7'b1111000; //"7"
                6'd8: res2_out <= 7'b0000000; //"8"
                6'd9: res2_out <= 7'b0010000; //"9"
            endcase
        end

    else if (result >= 6'd10) // an to apotelesma einai apo 10 kai pano (eos 18)
begin
res1_out <= 7'b1111001; //o protos aritmos tou apotelesmatos "1" (dipsifio apotelesma)

    case (result) //case gia to ti tha vgalei to seven segment tou deuterou arithmou tou apotelesmatos
        6'd10: res2_out <= 7'b1000000; // "0"
        6'd11: res2_out <= 7'b1111001; // "1"
        6'd12: res2_out <= 7'b0100100; // "2"
        6'd13: res2_out <= 7'b0110000; // "3"
        6'd14: res2_out <= 7'b0011001; // "4"
        6'd15: res2_out <= 7'b0010010; // "5"
        6'd16: res2_out <= 7'b0000010; // "6"
        6'd17: res2_out <= 7'b1111000; // "7"
        6'd18: res2_out <= 7'b0000000; // "8"
    endcase
end
end


    else
    begin
        eq_out <= 7'b0000110; //vgale sto seven segment tou ison "E" 
        state <= WAIT_F0; //pigaine stin katastasi WAIT_F0
    end
end

         WAIT_F0: //an eimaste stin katastasi WAIT_F0
begin
            if (keyb_data_reg[8:1] == 8'hF0) //an keyb_data_reg einai F0
               state <= AFTER_F0; //pigaine stin katastasi AFTER_F0
      
            else //allios
            state <= WAIT_F0; //meine stin idia katastasi
            end
         AFTER_F0: //an eimaste stin katastasi AFTER_F0
begin
            if (error == 1'b1) //an exei patithei lathos pliktro
               state <= previous_state; //pigaine stin proigoumeni katastasi
            else 
begin
               case (previous_state) //case gia to se poia katastasi tha pame
                  WAIT_OPERAND1: state <= WAIT_OPERATOR; //an imastan stin WAIT_OPERAND1 pame stin WAIT_OPERATOR
                  WAIT_OPERATOR: state <= WAIT_OPERAND2; //an imastan stin WAIT_OPERATOR pame stin WAIT_OPERAND2
                  WAIT_OPERAND2: state <= WAIT_EQ;  //an imastan stin WAIT_OPERAND2 pame stin WAIT_EQ
                  WAIT_EQ: state <= WAIT_OPERAND1;  //an imastan stin WAIT_EQ pame stin WAIT_OPERAND1 gia na ksekinisoume nea praksi
               endcase
            end
         end

default: begin //defalt periptosi i opoia dinei tis times pou dinei kai to reset
      state <= WAIT_OPERAND1;
      previous_state <= WAIT_OPERAND1;
      first_out <= 7'b1111111;
      sign_out <= 7'b1111111;
      second_out <= 7'b1111111;
      eq_out <= 7'b1111111;
      res1_out <= 7'b1111111;
      res2_out <= 7'b1111111;
      operand1 <= 6'b000000;
      operand2 <= 6'b000000;
   end
      endcase
   end
end

endmodule 


module calc_new_tb;

    reg keyb_clk;
    reg keyb_data;
    reg clk;
    reg reset;
    wire [6:0] first_out, sign_out, second_out, eq_out, res1_out, res2_out;

    calc_new cn (keyb_clk, keyb_data, clk, reset, first_out, sign_out, second_out, eq_out, res1_out, res2_out); //instatiation tou calc_new

    
    always #5 clk = ~clk; //dinoume palmo sto esoteriko roloi
    always #100 keyb_clk = ~keyb_clk; //dinoume palmo sto keyb_clk 20 fores megalytero apo to esoteriko roloi
   
  task send_keycode; //ylopoiisi task
    input [7:0] keycode; //gia ta 8 bit tou scan kodikou
    integer i; //metritis gia to for loop
    begin
        keyb_data = 0; // Start bit
        @(negedge keyb_clk); //kathisterisi mias arnitikis akmis tou keyb_clk
        for (i = 0; i < 8; i = i + 1) begin //for loop
            keyb_data = keycode[i]; //pare to i-osto bit keycode kai apothikeuse to sto keyb_data
            @(negedge keyb_clk);
        end
        keyb_data = 1; // Parity bit (tuxaia orizetai me 1)
        @(negedge keyb_clk);
        keyb_data = 1; // Stop bit
        @(negedge keyb_clk);
    end
endtask


    initial begin
      //arxikopoiiseis
        clk = 0;
        reset = 1;
        keyb_clk = 0;
        keyb_data = 1;
        @(negedge keyb_clk);
        reset = 0; //meta apo mia kathisterisi tou rologiou to reset ginetai 0 


//paradeigma praksis (athroisma apo 0 eos 9)
    @(negedge keyb_clk); 
        send_keycode(8'h7A); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 3 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h7A); //stelnei to teleutaio byte meta to F0

   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h74); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 6 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h74); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis (athroisma apo 10 kai pano)
  
        @(negedge keyb_clk); 
        send_keycode(8'h72); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 2 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h72); //stelnei to teleutaio byte meta to F0


   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h7D); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 9 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h7D); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis (thetiki diafora)
    @(negedge keyb_clk); 
        send_keycode(8'h75); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 8 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h75); //stelnei to teleutaio byte meta to F0



   @(negedge keyb_clk);
        send_keycode(8'h7B); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "-" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h7B); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h6C); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 7 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h6C); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis (arnitiki diafora)
    @(negedge keyb_clk); 
        send_keycode(8'h6B); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 4 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h6B); //stelnei to teleutaio byte meta to F0

   @(negedge keyb_clk);
        send_keycode(8'h7B); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "-" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h7B); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h73); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 5 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h73); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis me lathos pliktra endiamesa (sto operand1)
 @(negedge keyb_clk); 
        send_keycode(8'h29); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk patame lathos pliktro (space) anti gia ton proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h29); //stelnei to teleutaio byte meta to F0

    @(negedge keyb_clk); 
        send_keycode(8'h70); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 0 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h70); //stelnei to teleutaio byte meta to F0

   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h69); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 1 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h69); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis me lathos pliktra endiamesa (ston operator)

    @(negedge keyb_clk); 
        send_keycode(8'h70); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 0 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h70); //stelnei to teleutaio byte meta to F0

 @(negedge keyb_clk); 
        send_keycode(8'h29); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk patame lathos pliktro (space) anti gia ton telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h29); //stelnei to teleutaio byte meta to F0

   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h69); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 1 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h69); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis me lathos pliktra endiamesa (ston operand2)

    @(negedge keyb_clk); 
        send_keycode(8'h70); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 0 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h70); //stelnei to teleutaio byte meta to F0

 
   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0

@(negedge keyb_clk); 
        send_keycode(8'h29); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk patame lathos pliktro (space) anti gia ton deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h29); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h69); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 1 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h69); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0


//paradeigma praksis me lathos pliktra endiamesa (sto ison)

    @(negedge keyb_clk); 
        send_keycode(8'h70); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 0 gia proto telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h70); //stelnei to teleutaio byte meta to F0

 
   @(negedge keyb_clk);
        send_keycode(8'h79); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "+" gia telesti
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h79); //stelnei to teleutaio byte meta to F0


  @(negedge keyb_clk);
        send_keycode(8'h69); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile ton aritmo 1 gia deutero telesteo
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h69); //stelnei to teleutaio byte meta to F0


@(negedge keyb_clk); 
        send_keycode(8'h29); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk patame lathos pliktro (space) anti gia ton ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h29); //stelnei to teleutaio byte meta to F0

  @(negedge keyb_clk);
        send_keycode(8'h55); //meta apo mia kathisterisi tis arnitikis akmis tou keyb_clk steile to "=" gia to ison
        send_keycode(8'hF0); //afima koumpiou
        send_keycode(8'h55); //stelnei to teleutaio byte meta to F0



end 
endmodule 