#!/bin/python3
#
# romInfo.py - Epson PX-4 & PX-8 ROM capsule info program. 
#              parsed binary images of ROMS and report on contents, 
#              checking internal consistency.
#
# Source: OSRM II, 3.8.3.1 ROM capsule, p II-344

import sys
import os

def getRomHeaderAddr(fileName, fileSize):
    #  8k M & P: 0x0000
    # 16k M: 0x0000, 16k P: 0x2000
    # 32k M: 0x4000, 32k P: 0x6000
    MP8k = 0x0000
    M16k = 0x0000
    P16k = 0x2000
    M32k = 0x4000
    P32k = 0x6000
    sizeMargin = 1024
    if (fileSize >= 8192 - sizeMargin and fileSize < 8192 + sizeMargin):
        return (MP8k)
    elif (fileSize >= 16384 - sizeMargin and fileSize < 16384 + sizeMargin):
        file = open(fileName, 'rb')
        block0k = file.read(32)
        file.seek(P16k)
        block2k = file.read(32)
        file.close()
        print('0k: ' + hex(block0k[0]) + ' ' + hex(block0k[1]))
        print('2k: ' + hex(block2k[0]) + ' ' + hex(block2k[1]))
        if (block0k[0] == 0xE5 and block0k[1] == 0x37): # M
            return(M16k)
        elif (block2k[0] == 0xE5 and block2k[1] == 0x50): # P
            return(P16k)
        else:
            print('16 kByte header not found at 0x0000 (M) and 0x2000 (P)')
    elif (fileSize >= 32768 - sizeMargin and fileSize < 32768 + sizeMargin):
        file = open(fileName, 'rb')
        file.seek(M32k)
        block4k = file.read(32)
        file.seek(P32k)
        block6k = file.read(32)
        file.close()
        print('4k: ' + hex(block4k[0]) + ' ' + hex(block4k[1]))
        print('6k: ' + hex(block6k[0]) + ' ' + hex(block6k[1]))
        if (block4k[0] == 0xE5 and block4k[1] == 0x37): # M
            return(M32k)
        elif (block6k[0] == 0xE5 and block6k[1] == 0x50): # P
            return P32k
        else:
            print('32 kByte header not found at 0x4000 (M) and 0x6000 (P)')
    else:
        print('Unknown ROM size: ' + str(fileSize) + ', must be 8192, 16384 or 32768')
    return -1
    
def valueWithinMargin(value, reference, margin):
    if ((value > reference - margin) and (value < reference + margin)):
        return True
    return False

print('romInfo.py alpha 0.3  ** beware: cluster count or cluster mapping incorrect! **')
print()

fileName = ''
#fileName = '../CampbellROMs/ASM-DBG80.COM.BIN'
#fileName = '../CampbellROMs/PC_4.0_SPC_analyzer_ROM.BIN'
if (len(sys.argv) > 1):
    fileName = sys.argv[1]
if (not fileName):
    print('Usage: ' + sys.argv[0] + ' <romName>')
    sys.exit(1)

fileSize = os.path.getsize(fileName)
print('File size: ' + str(fileSize))
headerLocation = getRomHeaderAddr(fileName, fileSize)
if (headerLocation == -1):
    print('Error in header location: ' + str(headerLocation))
    exit(2)

print('"' + str(fileName) + '" size: ' + str(fileSize) + ' bytes')

file = open(fileName,"rb")
file.seek(headerLocation)
rawHeader = (file.read(32))
print('Raw header:')
print(rawHeader) 

if (rawHeader[0] == 0xe5):
    print(' 1st byte is E5h, Ok.')
else:
    print('1st byte not E5h, not ok.')

typeByte = rawHeader[1]
if (typeByte == 0x37):
    print(' 2nd byte is 37h, "M", for M-type ROM, Ok.')
elif (typeByte == 0x50):
    print(' 2nd byte is 50h, "P", for P-type ROM, Ok.')
else:
    print('2nd byte is not a valid ROM type: ' + hex(typeByte) + ' not ok.')

sizeByte = rawHeader[2]
if (sizeByte == 0x08):
    print(' 3rd byte is 08h, single 8 kByte ROM, Ok.')
elif (sizeByte == 0x88):
    print(' 3rd byte is 88h, first of double ROMs, 1st ROM is 8 kByte, Ok.')
elif (sizeByte == 0x10):
    print('	3rd byte is 10h, single 16 kByte ROM, Ok.')
elif (sizeByte == 0x90):
    print(' 3rd byte is 90h, first of double ROMs, 1st ROM is 16 kByte, Ok.')
elif (sizeByte == 0x20):
    print(' 3rd byte is 20h, single 32 kByte ROM, Ok.')
elif (sizeByte == 0xA0):
    print(' 3rd byte is A0h, first of double ROMs, 1st ROM is 32 kByte, Ok.') 
else:
    print('3rd byte not a valid ROM size: ' + hex(sizeByte) + ' not ok.')

sizeMargin = 1024
firstSize = sizeByte & 0x7F     # erase chained ROM bit

if ((firstSize == 0x08) and not valueWithinMargin(fileSize, 8192, sizeMargin)):
    print('sizeByte (' + hex(sizeByte) + ') does not match fileSize: ' + str(fileSize) + ', not ok.')
elif ((firstSize == 0x10) and not valueWithinMargin(fileSize, 16384, sizeMargin)):
    print('sizeByte (' + hex(sizeByte) + ') does not match fileSize: ' + str(fileSize) + ', not ok.')    
elif ((firstSize == 0x20) and not valueWithinMargin(fileSize, 32768, sizeMargin)):
    print('sizeByte (' + hex(sizeByte) + ') does not match fileSize: ' + str(fileSize) + ', not ok.')    
else:
    print(' Size byte ('+ hex(sizeByte) + ') matches file size(' + str(fileSize) + '), ok.')

defChecksum = (rawHeader[3] + rawHeader[4] * 256) & 0xFFFF
print(' 4th & 5th byte checksum is: ' + hex(defChecksum));

sysName = rawHeader[5:8].decode('utf-8')
print(' 6th to 8th byte is SYS NAME: \'' + str(sysName) + '\'')

romName = rawHeader[8:0x16].decode('utf-8')
print(' 9th to 20th byte is ROM NAME: \'' + str(romName) + '\'')

dirEntCount = rawHeader[0x16]
if (dirEntCount == 0x04 or dirEntCount == 0x08 or dirEntCount == 0x0C or dirEntCount == 0x10 or dirEntCount == 0x14 or dirEntCount == 0x1C or dirEntCount == 0x20):
    print(' 21th byte is directory entry count: ' + str(dirEntCount) + ', Ok.')
else:
    print('21th byte is directory entry count error: ' + str(dirEntCount) + ', not ok.')

sectorSize = 128
blockSize = sectorSize * 8
totalSize = (sizeByte & 0x7F) * 1024
header_dirSize =  dirEntCount * sectorSize
capacity =  totalSize - header_dirSize
capacityInBlocks = int(capacity / blockSize)
print(' ROM data capacity: (' + str(totalSize) + ' - ' + str(header_dirSize) + '): ' + str(capacity) + ', ' + str(capacityInBlocks) + '/' + hex(capacityInBlocks) + ' blocks (0x01-' + hex(capacityInBlocks+1) + ').')

vChar = rawHeader[0x17]
if (chr(vChar) == 'V'):
    print(' 22th byte is a \'V\', Ok.')
else:
    print('22th byte is not a \'V\' but a \'' + chr(vChar) + '\', not ok.')

version = rawHeader[0x18:0x1A].decode('utf-8')
print(' 23th & 24th byte are the ROM version: \'' + str(version) + '\'')

date = rawHeader[0x1A:0x20].decode('utf-8')
print(' 25th to 32th byte are the ROM date (MMDDYY): \'' + str(date) + '\'')

def dirEntry(entry):
#    print('raw: ' + str(entry))
    if (entry[0] == 0xE5):
        return(hex(entry[0]) + ' -- empty --')
    else:
        if (entry[9] > 0x7F):
            roBit =  'R'
        else:
            roBit =  '-'
        if (entry[10] > 0x7F):
            sysBit = 'S'
        else:
            sysBit = '-'
        if (entry[11] > 0x7F):
            arcBit = 'A'
        else:
            arcBit = '-'
        bits = roBit + sysBit + arcBit
        extend = str(int(entry[0x0C]))
        blocksUsed = '  '
        for block in range(0x10,0x20):
            if (entry[block] != 0):
                blocksUsed = blocksUsed + hex(block) + '/' + str(hex(entry[block])) + ' '
                
        retStr = str(entry[0]) + ':' + str(stripBit8(entry[1:12]))+ ' ' + extend + ' ' + bits + ' ' + str(blocksUsed)
        return(retStr)
        # 

def stripBit8(byteStr):
    newByteStr = ''
    for myChar in byteStr:
        newByteStr += chr(myChar & 0x7F)
    return newByteStr

dirBlocks = int(dirEntCount / 4)

print()
print('  name    ext e RSA     blocks used (dirEntryIndex/blockValue)')

for block in range(dirBlocks):
    print('  Directory block: ' + str(block))

    print(dirEntry(file.read(32)))	# 1
    print(dirEntry(file.read(32)))	# 2
    print(dirEntry(file.read(32)))	# 3
    if (block != 0):
        print(dirEntry(file.read(32)))	# 4

file.close()

