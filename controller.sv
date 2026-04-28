// ============================================================
// ELE432 HW2 - Multicycle RISC-V Controller
// Testbench-compatible implementation
// ============================================================

module controller(
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       zero,

    output logic [1:0] immsrc,
    output logic [1:0] alusrca, alusrcb,
    output logic [1:0] resultsrc,
    output logic       adrsrc,
    output logic [2:0] alucontrol,
    output logic       irwrite, pcwrite,
    output logic       regwrite, memwrite
);

    logic [1:0] aluop;
    logic       branch;
    logic       pcupdate;

    mainfsm fsm(
        .clk       (clk),
        .reset     (reset),
        .op        (op),
        .alusrca   (alusrca),
        .alusrcb   (alusrcb),
        .resultsrc (resultsrc),
        .adrsrc    (adrsrc),
        .irwrite   (irwrite),
        .regwrite  (regwrite),
        .memwrite  (memwrite),
        .aluop     (aluop),
        .branch    (branch),
        .pcupdate  (pcupdate)
    );

    aludec ad(
        .opb5       (op[5]),
        .funct3     (funct3),
        .funct7b5   (funct7b5),
        .aluop      (aluop),
        .alucontrol (alucontrol)
    );

    instrdec id(
        .op     (op),
        .immsrc (immsrc)
    );

    assign pcwrite = pcupdate | (branch & zero);

endmodule


// ============================================================
// Main FSM
// ============================================================

module mainfsm(
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,

    output logic [1:0] alusrca,
    output logic [1:0] alusrcb,
    output logic [1:0] resultsrc,
    output logic       adrsrc,
    output logic       irwrite,
    output logic       regwrite,
    output logic       memwrite,
    output logic [1:0] aluop,
    output logic       branch,
    output logic       pcupdate
);

    typedef enum logic [3:0] {
        FETCH    = 4'd0,
        DECODE   = 4'd1,
        MEMADR   = 4'd2,
        MEMREAD  = 4'd3,
        MEMWB    = 4'd4,
        MEMWRITE = 4'd5,
        EXECUTER = 4'd6,
        ALUWB    = 4'd7,
        EXECUTEI = 4'd8,
        JAL      = 4'd9,
        BEQ      = 4'd10
    } statetype;

    statetype state, nextstate;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;
    end

    always_comb begin
        case (state)

            FETCH:
                nextstate = DECODE;

            DECODE: begin
                case (op)
                    7'b0000011: nextstate = MEMADR;    // lw
                    7'b0100011: nextstate = MEMADR;    // sw
                    7'b0110011: nextstate = EXECUTER;  // R-type
                    7'b0010011: nextstate = EXECUTEI;  // I-type ALU
                    7'b1101111: nextstate = JAL;       // jal
                    7'b1100011: nextstate = BEQ;       // beq
                    default:    nextstate = FETCH;
                endcase
            end

            MEMADR: begin
                case (op)
                    7'b0000011: nextstate = MEMREAD;   // lw
                    7'b0100011: nextstate = MEMWRITE;  // sw
                    default:    nextstate = FETCH;
                endcase
            end

            MEMREAD:
                nextstate = MEMWB;

            MEMWB:
                nextstate = FETCH;

            MEMWRITE:
                nextstate = FETCH;

            EXECUTER:
                nextstate = ALUWB;

            EXECUTEI:
                nextstate = ALUWB;

            ALUWB:
                nextstate = FETCH;

            JAL:
                nextstate = ALUWB;

            BEQ:
                nextstate = FETCH;

            default:
                nextstate = FETCH;

        endcase
    end

    always_comb begin
        // Default deterministic values
        alusrca   = 2'b00;
        alusrcb   = 2'b00;
        resultsrc = 2'b00;
        adrsrc    = 1'b0;
        irwrite   = 1'b0;
        regwrite  = 1'b0;
        memwrite  = 1'b0;
        aluop     = 2'b00;
        branch    = 1'b0;
        pcupdate  = 1'b0;

        case (state)

            FETCH: begin
                adrsrc    = 1'b0;
                irwrite   = 1'b1;
                alusrca   = 2'b00;
                alusrcb   = 2'b10;
                aluop     = 2'b00;
                resultsrc = 2'b10;
                pcupdate  = 1'b1;
            end

            DECODE: begin
                alusrca = 2'b01;
                alusrcb = 2'b01;
                aluop   = 2'b00;
            end

            MEMADR: begin
                alusrca = 2'b10;
                alusrcb = 2'b01;
                aluop   = 2'b00;
            end

            MEMREAD: begin
                resultsrc = 2'b00;
                adrsrc    = 1'b1;
            end

            MEMWB: begin
                resultsrc = 2'b01;
                regwrite  = 1'b1;
            end

            MEMWRITE: begin
                resultsrc = 2'b00;
                adrsrc    = 1'b1;
                memwrite  = 1'b1;
            end

            EXECUTER: begin
                alusrca = 2'b10;
                alusrcb = 2'b00;
                aluop   = 2'b10;
            end

            ALUWB: begin
                resultsrc = 2'b00;
                regwrite  = 1'b1;
            end

            EXECUTEI: begin
                alusrca = 2'b10;
                alusrcb = 2'b01;
                aluop   = 2'b10;
            end

            JAL: begin
                alusrca   = 2'b01;
                alusrcb   = 2'b10;
                aluop     = 2'b00;
                resultsrc = 2'b00;
                pcupdate  = 1'b1;
            end

            BEQ: begin
                alusrca   = 2'b10;
                alusrcb   = 2'b00;
                aluop     = 2'b01;
                resultsrc = 2'b00;
                branch    = 1'b1;
            end

            default: begin
                alusrca   = 2'b00;
                alusrcb   = 2'b00;
                resultsrc = 2'b00;
                adrsrc    = 1'b0;
                irwrite   = 1'b0;
                regwrite  = 1'b0;
                memwrite  = 1'b0;
                aluop     = 2'b00;
                branch    = 1'b0;
                pcupdate  = 1'b0;
            end

        endcase
    end

endmodule


// ============================================================
// ALU Decoder
// This encoding matches the provided controller.tv file:
// and = 000, or = 001, add = 010, sub = 110, slt = 111
// ============================================================

module aludec(
    input  logic       opb5,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic [1:0] aluop,
    output logic [2:0] alucontrol
);

    logic rtypesub;

    assign rtypesub = funct7b5 & opb5;

    always_comb begin
        case (aluop)

            2'b00:
                alucontrol = 3'b010;   // add

            2'b01:
                alucontrol = 3'b110;   // subtract

            default: begin
                case (funct3)

                    3'b000: begin
                        if (rtypesub)
                            alucontrol = 3'b110; // sub
                        else
                            alucontrol = 3'b010; // add, addi
                    end

                    3'b010:
                        alucontrol = 3'b111;     // slt, slti

                    3'b110:
                        alucontrol = 3'b001;     // or, ori

                    3'b111:
                        alucontrol = 3'b000;     // and, andi

                    default:
                        alucontrol = 3'b010;     // deterministic default

                endcase
            end

        endcase
    end

endmodule


// ============================================================
// Instruction Decoder
// R-type is XX because the provided controller.tv expects XX.
// ============================================================

module instrdec(
    input  logic [6:0] op,
    output logic [1:0] immsrc
);

    always_comb begin
        case (op)

            7'b0110011:
                immsrc = 2'bxx; // R-type, matches provided test vector

            7'b0010011:
                immsrc = 2'b00; // I-type ALU

            7'b0000011:
                immsrc = 2'b00; // lw

            7'b0100011:
                immsrc = 2'b01; // sw

            7'b1100011:
                immsrc = 2'b10; // beq

            7'b1101111:
                immsrc = 2'b11; // jal

            default:
                immsrc = 2'bxx;

        endcase
    end

endmodule
