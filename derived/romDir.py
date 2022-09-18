#!/bin/python3
#
# romDir.py - Epson PX-4 & PX-8 ROM capsule directory program. 
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

if (rawHeader[0] != 0xe5):
    print('1st byte not E5h, not ok.')
    exit(3)

typeByte = rawHeader[1]
if (typeByte == 0x37):
    print(' ROM type M')
elif (typeByte == 0x50):
    print(' ROM type P')
else:
    print('Not a valid ROM type: ' + hex(typeByte) + ' not ok.')
    exit(4)

sizeByte = rawHeader[2]
if (sizeByte != 0x08 and sizeByte != 0x88 and sizeByte != 0x10 and sizeByte != 0x90 and sizeByte != 0x20 and sizeByte != 0xA0):
    print('Not a valid ROM size: ' + hex(sizeByte) + ' not ok.')
    exit(6)

sizeMargin = 1024
firstSize = sizeByte & 0x7F     # erase chained ROM bit

sysName = rawHeader[5:8].decode('utf-8')
print(' SYS NAME: \'' + str(sysName) + '\'')

romName = rawHeader[8:0x16].decode('utf-8')
print(' ROM NAME: \'' + str(romName) + '\'')

dirEntCount = rawHeader[0x16]
if (dirEntCount == 0x04 or dirEntCount == 0x08 or dirEntCount == 0x0C or dirEntCount == 0x10 or dirEntCount == 0x14 or dirEntCount == 0x1C or dirEntCount == 0x20):
    print(' Directory entry count: ' + str(dirEntCount))
else:
    print('Directory entry count error: ' + str(dirEntCount) + ', not ok.')
    exit(7)

sectorSize = 128
blockSize = sectorSize * 8
totalSize = (sizeByte & 0x7F) * 1024
header_dirSize =  int(dirEntCount / 4 * sectorSize)
capacity =  totalSize - header_dirSize
capacityInBlocks = int(capacity / blockSize)
print(' ROM data capacity: (' + str(totalSize) + ' - ' + str(header_dirSize) + '): ' + str(capacity) + ', ' + str(capacityInBlocks) + '/' + hex(capacityInBlocks) + ' blocks (0x01-' + hex(capacityInBlocks) + ').')

version = rawHeader[0x17:0x1A].decode('utf-8')
print(' ROM version: \'' + str(version) + '\'')

date = rawHeader[0x1A:0x20].decode('utf-8')
print(' ROM date (MMDDYY): \'' + str(date) + '\'')

def addSpaces(count):
        sp = ''
        for c in range(count):
                sp += ' '
        return sp
        
def dirEntry(entry):
#    print('raw: ' + str(entry))
    if (entry[0] == 0xE5):
        return('')
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
        size = 0
        for block in range(0x10,0x20):
            if (entry[block] != 0):
                size += blockSize
        sizeStr = ''
        if (size < 10000):
                sizeStr = ' ' + str(size)
        else:
                sizeStr = str(size)
        fileName = str(stripBit8(entry[1:9])).strip() + '.' + str(stripBit8(entry[9:12])).strip()
        fnLen = 13 - len(fileName)
        retStr = str(entry[0]) + ':' + fileName + addSpaces(fnLen) + ' ' + extend + ' ' + bits + '   ' + sizeStr
        return(retStr)
        # 

def stripBit8(byteStr):
    newByteStr = ''
    for myChar in byteStr:
        newByteStr += chr(myChar & 0x7F)
    return newByteStr

dirBlocks = int(dirEntCount / 4)

print()
print('U name            RSA   size')

for block in range(dirBlocks):
    print(dirEntry(file.read(32)))	# 1
    print(dirEntry(file.read(32)))	# 2
    print(dirEntry(file.read(32)))	# 3
    if (block != 0):
        print(dirEntry(file.read(32)))	# 4

file.close()

