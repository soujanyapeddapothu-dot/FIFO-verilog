vlib work
vlog asynch.v
vsim top +testcase=test_nwr_nrd
add wave -position insertpoint sim:/top/*
run -all
