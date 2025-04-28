`ifndef FREQ
    `define FREQ 10_000_000
`endif

`ifndef DOUBLE
    `define DOUBLE 1
`endif

`ifndef MODE
    `define MODE ""
`endif

`ifndef Nlins
    `define Nlins 30
`endif

`ifndef PROP
    `define PROP 1
`endif

`ifndef vector
    `define vector "../vetor.txt"
`endif

module multiplier32FP_tb #(parameter int FREQ = `FREQ, parameter bit double = `DOUBLE, parameter string MODE = `MODE, parameter bit prop = `PROP); // double: 1 para MAX, 0 para MIN
    parameter int PERIOD = (1.0/FREQ)*10**9;

    parameter int col = (prop) ? 2 : 1;

    logic [31:0] data [0:`Nlins][col:0];

    logic [31:0] a [0:`Nlins];
    logic [31:0] b [0:`Nlins];
    logic [31:0] res [0:`Nlins];

    logic [31:0] a_i, b_i;
    logic [31:0] product_o;
    logic clk, rst_n;
    logic start_i;
    logic done_o;
    logic nan_o;
    logic infinit_o;
    logic overflow_o;
    logic underflow_o;

    multiplier32FP U1 (.start_i(start_i), .clk(clk), .rst_n(rst_n), .a_i(a_i), .b_i(b_i), .product_o(product_o), .done_o(done_o), .nan_o(nan_o), .infinit_o(infinit_o), .overflow_o(overflow_o), .underflow_o(underflow_o));

    initial begin
        clk = 1;
        forever #(PERIOD/2) clk = ~clk;
    end

    int i;

    int correct, wrong;

    initial begin
        int t;

        correct = 0;
        wrong = 0;

        start_i = 0;
        rst_n = 0;
        #PERIOD
        rst_n = 1;

        #(PERIOD*9);
        $readmemh(`vector, data);

        for (i = 0; i < `Nlins; i++) begin
            a[i] = data[i][0];
            b[i] = data[i][1];
            res[i] = data[i][2];
        end

        $display("+------------------------------------------------+");

        for (i = 0; i < `Nlins; i++) begin
            a_i = a[i];
            b_i = b[i];
            start_i = 1;
            #PERIOD;
            start_i = 0;
            wait(done_o);
            wait(~done_o);

            if (prop) begin
                assert (product_o == res[i]) begin
                    $display("Assertion %d passed!", i+1);
                    correct += 1;
                end
                    else begin
                        $warning("Assertion %d failed!", i+1);
                        wrong += 1;
                    end
            end
            
            $display("%h %h %h", a_i, b_i, product_o);
            $display("+-------caso %1d binario-------------------------+", i+1);
            $display("a_i:       %h", a_i);
            $display("b_i:       %h", b_i);
            $display("product_o: %h", product_o);
            if (prop)
                $display("expected:  %h", res[i]);

            $display("+-------caso %1d decimal-------------------------+", i+1);
            $display("a_i:       %f", $bitstoshortreal(a_i));
            $display("b_i:       %f", $bitstoshortreal(b_i));
            $display("product_o: %f", $bitstoshortreal(product_o));
            if (prop)
                $display("expected:  %f", $bitstoshortreal(res[i]));

            $display("+------------------------------------------------+");
            
            #(PERIOD*2);
        end
        t=$time;
        if (double) #t;
        $display("+------------------------------------------------+");
        if (prop) begin
            $display("Assertions passed: %d", correct);
            $display("Assertions failed: %d", wrong);
        end
        $finish;
    end

    string s;
    
    initial begin
        if (double) begin
            s = $sformatf("../deliverables/multiplier32FP_%0dns%s_MAX.vcd", PERIOD, MODE);
            $dumpfile(s);
            $dumpvars(0, multiplier32FP_tb);
        end else begin
            s = $sformatf("../deliverables/multiplier32FP_%0dns%s_MIN.vcd", PERIOD, MODE);
            $dumpfile(s);
            $dumpvars(0, multiplier32FP_tb);
        end
    end

endmodule

