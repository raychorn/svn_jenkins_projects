import re, os, sys

__start_target__ = '#!/bin/sh'
__end_target__ = '### BEGIN INIT INFO'

__re__ = re.compile("^%s$.*^%s$" % (__start_target__,__end_target__), re.DOTALL | re.MULTILINE)
__re1__ = re.compile("%s" % (__start_target__), re.MULTILINE)
__re2__ = re.compile("%s" % (__end_target__), re.MULTILINE)

fpath = '/etc/init.d/nagios'
if (os.path.exists(fpath)):
    fIn = open(fpath, 'r')
    lines = fIn.readlines()
    fIn.close()

    content = ''.join(lines)

    print content

    matches = __re__.search(content)
    if (matches):
        snippet = content[matches.start():matches.end()]
        matches1 = __re1__.search(snippet)
        matches2 = __re2__.search(snippet)
        if (matches1 and matches2) and (matches1.end() < matches2.start()):
            snippet2 = content[matches1.end():matches2.start()]
            c = content.replace(snippet2, '\n')
            fOut = open(fpath+'.new', mode='w')
            lines = c.split('\n')
            for l in lines:
                print >> fOut, str(l).rstrip()
            fOut.flush()
            fOut.close()
            
            os.remove(fpath)
            os.rename(fOut.name,fpath)
            
        else:
            print >> sys.stderr, 'WARNING: Cannot match regex in the snippet.'
        print 'INFO: matches=%s' % (matches)
    else:
        print >> sys.stderr, 'WARNING: Cannot match your regex.'

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
