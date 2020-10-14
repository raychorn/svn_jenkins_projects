import re, os, sys

try:
    logfilename = sys.argv[-1]
except:
    logfilename = None


if (os.path.exists(logfilename)):
    fIn = open(logfilename, 'r')
    lines = fIn.readlines()
    fIn.close()
    
    reports = []
    
    report = []
    report_weight = 0
    for aline in lines:
        report.append(aline)
        report_weight += len(aline)
        count = len([ch for ch in aline if (not str(ch).isalnum())])
        if (count > (report_weight / len(report))):
            reports.append(report)
            report = []
            report_weight = 0
    if (len(reports) > 100):
        print >> sys.stdout, 'INFO: Truncating %s lines.' % (len(reports[0:-100]))
        del reports[0:-100]
    fOut = open(logfilename, mode='w')
    for report in  reports:
        for l in report:
            print >> fOut, str(l).strip()
    fOut.flush()
    fOut.close()
else:
    print >> sys.stderr, 'WARNING: Missing the logfilename as the first parameter.'
    
