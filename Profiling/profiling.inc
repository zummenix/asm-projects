macro ProfilingStart dLClock,dHClock
{
        xor     eax,eax
        cpuid
        rdtsc
        mov     dLClock,eax
        mov     dHClock,edx
}

macro ProfilingEnd dLClock,dHClock,lpOut,lpFmt
{
        xor     eax,eax
        cpuid
        rdtsc
        sub     eax,dLClock
        sbb     edx,dHClock
        cinvoke wsprintf,lpOut,lpFmt,edx,eax
        invoke  MessageBox,0,lpOut,0,0
}