

l=-2.5
r=2.5
b=-1.25
t=1.25
w=512
h=256

def pixel2ComplexInWindow(col, row):
    x=(col/w)*(r-l) + l
    y=(row/h)*(t-b) + b

    return (x,y)

res=pixel2ComplexInWindow(0,0)
print(res[0])
print(res[1])



