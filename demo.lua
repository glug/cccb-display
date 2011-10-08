require"display";F=function(f,t,s,b)for i=f,t,s do b(i)end
end;C=function(c,l,r)return(c and l or r)end;d=display;c=
d.config;w,h=c.width,c.height-1;u=d.udp;p=u.gfx_rawput;r=
u.gfx_display;a=u.alllum;m=math.fmod;s=function(e)return((
-1)^e)end;F(1,w*h-1,1,function(i)p(i,1,255-m(i,256));r()end
)F(1,3,1,function(j)local x=j==2;F(C(x,10,1),C(x,2,11),s(j+
1),a)end)

