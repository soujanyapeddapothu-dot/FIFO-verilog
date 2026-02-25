module asynchfifo(wr_clk,rd_clk,res,wr_en,wdata,full,overflow,rd_en,rdata,empty,underflow);
parameter width=8;
parameter depth=16;
parameter ptr_width=$clog2(depth);
input wr_clk,rd_clk,res,wr_en,rd_en;
input [width-1:0]wdata;
output reg[width-1:0]rdata;
output reg full,overflow,empty,underflow;
integer i;
reg [width-1:0]asynchfifo[depth-1:0];
reg [ptr_width-1:0]wr_ptr,rd_ptr;
reg wr_toggle_f,rd_toggle_f;
// synchronized pointers
reg [ptr_width-1:0]rd_ptr_wr_clk,wr_ptr_rd_clk;
reg rd_toggle_f_wr_clk,wr_toggle_f_rd_clk;

/////////////////////////////////////////////////////////
// WRITE DOMAIN
/////////////////////////////////////////////////////////
always @(posedge wr_clk) begin
if(res==1) begin
    full=0;
    overflow=0;
    wr_ptr=0;
    wr_toggle_f=0;
    rd_ptr_wr_clk=0;
    rd_toggle_f_wr_clk=0;
end
else begin

    // synchronize read pointer into write clock
    rd_ptr_wr_clk = rd_ptr;
    rd_toggle_f_wr_clk = rd_toggle_f;

    if(wr_en==1) begin
        if(full==1) begin
            overflow=1;
        end
        else begin
            asynchfifo[wr_ptr]=wdata;

            if(wr_ptr==depth-1) begin
                wr_toggle_f=~wr_toggle_f;
                wr_ptr=0;
            end
            else begin
                wr_ptr=wr_ptr+1;
            end
        end
    end
end
end

/////////////////////////////////////////////////////////
// READ DOMAIN
/////////////////////////////////////////////////////////
always @(posedge rd_clk) begin
if(res==1) begin
    empty=1;
    underflow=0;
    rd_ptr=0;
    rd_toggle_f=0;
    wr_ptr_rd_clk=0;
    wr_toggle_f_rd_clk=0;
    rdata=0;
end
else begin

    // synchronize write pointer into read clock
    wr_ptr_rd_clk = wr_ptr;
    wr_toggle_f_rd_clk = wr_toggle_f;

    if(rd_en==1) begin
        if(empty==1) begin
            underflow=1;
        end
        else begin
            rdata=asynchfifo[rd_ptr];

            if(rd_ptr==depth-1) begin
                rd_toggle_f=~rd_toggle_f;
                rd_ptr=0;
            end
            else begin
                rd_ptr=rd_ptr+1;
            end
        end
    end
end
end

/////////////////////////////////////////////////////////
// FULL & EMPTY LOGIC
/////////////////////////////////////////////////////////
always @(*) begin

full=0;
empty=0;

// FULL condition
if((wr_ptr==rd_ptr_wr_clk) && (wr_toggle_f!=rd_toggle_f_wr_clk))
    full=1;

// EMPTY condition
if((wr_ptr_rd_clk==rd_ptr) && (wr_toggle_f_rd_clk==rd_toggle_f))
    empty=1;
end
endmodule


module top;
parameter width=8;
parameter depth=16;
parameter ptr_width=$clog2(depth);
reg wr_clk,rd_clk,res,wr_en,rd_en;
reg [ptr_width-1:0]wdata;
wire[ptr_width-1:0]rdata;
wire full,overflow,empty,underflow;
integer i;
reg [35*8:0]testname;
asynchfifo #(.depth(depth),.ptr_width(ptr_width)) dut(.wr_clk(wr_clk),.rd_clk(rd_clk),.res(res),.wr_en(wr_en),.wdata(wdata),.full(full),.overflow(overflow),.rd_en(rd_en),.rdata(rdata),.empty(empty),.underflow(underflow));
initial begin
wr_clk=0;
forever #5 wr_clk=~wr_clk;
end
initial begin
rd_clk=0;
forever #7 rd_clk=~rd_clk;
end
initial begin
reset_fifo();
$value$plusargs("testcase=%0s",testname);
$display("pass the testname=%0s",testname);
$display("--------------------------------");
case(testname)
"test_1wr":begin
write_fifo(0,1);
end
"test_5wr":begin
write_fifo(0,5);
end
"test_nwr":begin
write_fifo(0,depth);
end
"test_1wr_1rd":begin
write_fifo(0,1);
read_fifo(0,1);
end
"test_5wr_5rd":begin
write_fifo(0,5);
read_fifo(0,5);
end
"test_nwr_nrd":begin
write_fifo(0,depth);
read_fifo(0,depth);
end
"test_full":begin
write_fifo(0,full);
end
"test_overflow":begin
write_fifo(0,depth+5);
end
"test_empty":begin
read_fifo(0,depth);
end
"test_underflow":begin
read_fifo(0,depth+6);
end
"test_under_overflow":begin
write_fifo(0,depth+8);
read_fifo(0,depth+6);
end
endcase
#300;
$finish;
end
task reset_fifo();
begin
res=1;
wr_en=0;
rd_en=0;
wdata=0;
repeat (2)@(posedge wr_clk);
res=0;
end
endtask
task write_fifo(input integer start_loc,end_loc);
begin
for(i=0;i<depth;i=i+1)begin
@(posedge wr_clk);
wr_en=1;
wdata=$random;
$display("wdata=%0d",wdata);
end
@(posedge wr_clk);
wr_en=0;
wdata=0;
end
endtask
task read_fifo(input integer start_loc,end_loc);
begin
for(i=0;i<depth;i=i+1)begin
@(posedge rd_clk);
rd_en=1;
$display("rdata=%0d",rdata);
end
@(posedge rd_clk);
rd_en=0;
end
endtask
endmodule







