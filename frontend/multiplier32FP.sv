module multiplier32FP (start_i, clk, rst_n, a_i, b_i, product_o, done_o, nan_o, infinit_o, overflow_o, underflow_o);

    input logic [31:0] a_i, b_i;
    input logic start_i, clk, rst_n;
    output logic done_o;
    output logic nan_o;
    output logic infinit_o;
    output logic overflow_o;
    output logic underflow_o;
    output logic [31:0] product_o;

    logic [31:0] a_temp, b_temp;
    logic [23:0] mantA, mantB;
    logic [47:0] resmult;
    logic [9:0] expadd;
    logic signal;
    logic [31:0] product_temp, product;

    logic [4:0] msb;

    typedef enum logic [1:0] { idle, mult } states;

    states current, next;

    logic[3:0] counter, counter_ff;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            product_o <= 0;
            current <= idle;
            counter_ff <= 0;
        end
        else begin
            product_o <= product;
            current <= next;
            counter_ff <= counter;
        end
    end

    always_comb begin
        a_temp = a_i;
        b_temp = b_i;
        next = current;
        counter = 0;
        signal = 0;
        expadd = 0;
        mantA = 0;
        mantB = 0;
        resmult = 0;
        product_temp = 0;
        done_o = 0;
        nan_o = 0;
        infinit_o = 0;
        overflow_o = 0;
        underflow_o = 0;
        product = product_o;
        msb = 0;

        case (current)
            idle: begin
                if (start_i)
                        next = mult;
            end
            mult: begin
                counter = counter_ff + 1;
                
                // Verifica se pelo menos um dos números é NaN
                if (a_temp[30:23] == ~8'b0 & a_temp[22:0] != 0 || b_temp[30:23] == ~8'b0 & b_temp[22:0] != 0) begin
                    product_temp = {1'b0, {31{1'b0}}};
                    if (counter_ff == 1)
                        nan_o = 1;
                end
                else begin

                    mantA = {1'b1, a_temp[22:0]};
                    mantB = {1'b1, b_temp[22:0]};

                    // Ajusta as mantissas caso as entradas sejam não normalizadas
                    if (a_temp[30:23]==0)
                        mantA = {1'b0, a_temp[22:0]};
                    if (b_temp[30:23]==0)
                        mantB = {1'b0, b_temp[22:0]};

                    // Calcula o sinal da operação
                    signal = a_temp[31] ^ b_temp[31];

                    // Calcula o valor do expoente para números normalizados
                    expadd = a_temp[30:23] + b_temp[30:23] - 127;

                    // Calcula o valor da multiplicação das mantissas
                    resmult = mantA * mantB;

                    // Verifica se pelo menos um dos números da entrada é não normalizado
                    if (a_temp[30:23]==0 && b_temp[30:23]!=0 || a_temp[30:23]!=0 && b_temp[30:23]==0)
                        // Calcula o valor do expoente para números não normalizados
                        expadd = a_temp[30:23] + b_temp[30:23] - 126;

                    // Caso o bit mais signifcativo de resultado da multiplicação dê 1 (1*2^1)
                    if (resmult[47]) begin
                        resmult = resmult >> 1;
                        expadd = expadd + 1;
                    end

                    // Ajusta para permitir apresentar resultados desnormalizados
                    if (resmult[47:46] == 0 || expadd == 0 || (expadd >= -10'd23)) begin
                        resmult = resmult >> (~expadd + 10'd2);
                        expadd = 0;
                    end

                    // Verifica se os dois números são diferentes de zero
                    if (a_temp[30:0] !=0 && b_temp[30:0] !=0 )
                        product_temp = {signal, expadd[7:0], resmult[45:23]};
                    else
                        product_temp = {signal, {31{1'b0}}};

                    // Verifica se pelo menos um dos números é infinito
                    if (a_temp[30:23] == ~8'b0 & a_temp[22:0] == 0 || b_temp[30:23] == ~8'b0 & b_temp[22:0] == 0)begin
                        product_temp = {signal, {31{1'b1}}};
                        if (counter_ff == 1)
                            infinit_o = 1;
                    end
                    // Bit mais significativo 0 indica que é positivo, maior que 254 (maior valor válido)
                    else if (~expadd[9] && expadd > 254) begin
                        product_temp = {signal,{31{1'b1}}};
                        if (counter_ff == 1)
                            overflow_o = 1;
                    end
                    // Verifica se ambos os número são desnormalizados (sempre underflow)
                    else if (a_temp[30:23]==0 && a_temp[22:0] != 0 && b_temp[30:23]==0 && b_temp[22:0] != 0)begin
                        product_temp = 0;
                        if (counter_ff == 1)
                            underflow_o = 1;
                    end
                    else if (a_temp[30:0] != 0 && b_temp[30:0] != 0 && product_temp==0) begin
                        product_temp = 0;
                        if (counter_ff == 1)
                            underflow_o = 1;
                    end
                    // Bit mais significativo indica o sinal
                    else if (expadd[9]) begin
                        product_temp = 0;
                        if (counter_ff == 1)
                            underflow_o = 1;
                    end
                end
                
                product = product_temp;

                // se couter_ff for 1
                if (counter_ff == 1)begin
                    next = idle;
                    counter = 0;
                    done_o = 1;
                end
            end
        endcase

        // Caso reset
        if (~rst_n) begin
            signal = 0;
            expadd = 0;
            mantA = 0;
            mantB = 0;
            resmult = 0;
            product_temp = 0;
            counter = 0;
            product = 0;
        end

    end

endmodule

