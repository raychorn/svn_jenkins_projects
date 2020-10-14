import re, os, sys

def __matches__(regex,lines):
    matches = []
    iLine = 0
    for l in lines:
        m = regex.search(l)
        if (m):
            matches.append((m,iLine))
            print '%s (%s) --> %s' % (m,m.start(),l)
            print 'FOUND: %s' % (l)
        iLine += 1
    return matches

__re__ = re.compile("^command_file=(?P<command_file>.*)$", re.DOTALL | re.MULTILINE)
__re2__ = re.compile(r"^#\s*COMMAND\s*FILE$", re.DOTALL | re.MULTILINE)
fpath = sys.argv[-2]
__cmd__ = sys.argv[-1]
print 'fpath --> %s' % (fpath)
if (os.path.exists(fpath)):
    fIn = open(fpath, 'r')
    lines = fIn.readlines()
    fIn.close()

    fOut = open(fpath+'.new', 'w')
    matches = __matches__(__re__, lines)
    m = matches[-1]
    m,ii = m
    i = ii + 1
    while (i > 0):
        ll = lines[i]
        m = __re2__.search(ll)
        if (m):
            break
        i -= 1
    while (1):
        __lines__ = lines[i:ii]
        matches2 = __matches__(__re__, __lines__)
        if (len(matches) == len(matches2)):
            mm,ij = matches[0]
            while (len(str(lines[ii]).strip()) > 0):
                ii += 1
            retirees = lines[ij:ii+1]
            del lines[ij:ii+1]
            #lines.insert(ij, ll)
            lines.insert(ii-len(retirees)+1, 'command_file=%s\n' % (__cmd__.split('=')[-1]))
            break
        ii += 1
    for l in lines:
        print >> fOut, str(l).rstrip()
    fOut.flush()
    fOut.close()

    os.remove(fpath)
    os.rename(fOut.name,fpath)

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
