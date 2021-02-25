// this is nice code I extracted from
// ulx3s-misc/examples/dvi/top/top_vgatest.v
function integer F_find_next_f(input integer f);
    if(25000000>f)
        F_find_next_f=25000000;
    else if(27000000>f)
        F_find_next_f=27000000;
    else if(40000000>f)
        F_find_next_f=40000000;
    else if(50000000>f)
        F_find_next_f=50000000;
    else if(54000000>f)
        F_find_next_f=54000000;
    else if(60000000>f)
        F_find_next_f=60000000;
    else if(65000000>f)
        F_find_next_f=65000000;
    else if(75000000>f)
        F_find_next_f=75000000;
    else if(80000000>f)
        F_find_next_f=80000000;  // overclock
    else if(100000000>f)
        F_find_next_f=100000000; // overclock
    else if(108000000>f)
        F_find_next_f=108000000; // overclock
    else if(120000000>f)
        F_find_next_f=120000000; // overclock
endfunction

localparam xadjustf           =  0; // adjust -3..3 if no picture
localparam yadjustf           =  0; // or to fine-tune f
localparam xminblank         = x_res / 64; // initial estimate
localparam yminblank         = y_res / 64; // for minimal blank space

localparam min_pixel_f       = frame_rate*(x_res+xminblank)*(y_res+yminblank);
localparam pixel_f           = F_find_next_f(min_pixel_f);
localparam yframe            = y_res+yminblank;
localparam xframe            = pixel_f/(frame_rate*yframe);
localparam xblank            = xframe-x_res;
localparam yblank            = yframe-y_res;
localparam hsync_front_porch = xblank/3;
localparam hsync_pulse_width = xblank/3;
localparam hsync_back_porch  = xblank-hsync_pulse_width-hsync_front_porch+xadjustf;
localparam vsync_front_porch = yblank/3;
localparam vsync_pulse_width = yblank/3;
localparam vsync_back_porch  = yblank-vsync_pulse_width-vsync_front_porch+yadjustf;

initial begin
    $display("DISPLAY => frame rate:%d\t", frame_rate);
    $display("DISPLAY => pixel clock:%d\t", pixel_f);
    $display("DISPLAY => xframe:%d\t", xframe);
    $display("DISPLAY => yframe:%d\t", yframe);
    $display("DISPLAY => xblank:%d\t", xblank);
    $display("DISPLAY => yblank:%d\t", yblank);
    $display("DISPLAY => hsync front porch:%d\t", hsync_front_porch);
    $display("DISPLAY => hsync back porch:%d\t", hsync_back_porch);
    $display("DISPLAY => hsync pulse width:%d\t", hsync_pulse_width);
    $display("DISPLAY => vsync front porch:%d\t", vsync_front_porch);
    $display("DISPLAY => vsync back porch:%d\t", vsync_back_porch);
    $display("DISPLAY => vsync pulse width:%d\t", vsync_pulse_width);

end
