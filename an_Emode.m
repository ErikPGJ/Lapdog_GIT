%an_Emode


function [] = an_Emode(afoutarr) %%electrif field mode

len = length(afoutarr{1,1});



a = 1;



for i=1:len
    
    if afoutarr{i,7} ==1
        
V_SC = afoutarr{i,4}*a; %%let's assume V_SC = k* Vb here, as V(r) prop to 1/r
       



    
        
    end

end