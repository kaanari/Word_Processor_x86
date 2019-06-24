; Disks.inc - Include file for the Disks.asm 
; library module.

ParameterStruc struc 
  specialFunctions   db ?
  deviceType         db ?
  deviceAttributes   dw ?
  numberCylinders    dw ?
  mediaType          db ?
  bytesPerSector     dw ? 
  sectorsPerCluster  db ?
  reservedSectors    dw ?
  numberOfFATs       db ?
  maxRootDirEntries  dw ?
  numberOfSectors    dw ?
  mediaDescriptor    db ?
  sectorsPerFAT      dw ?
  sectorsPerTrack    dw ?
  numberOfHeads      dw ?
  numHiddenSectors   dd ?
  numberSectorsLong  dd ?   ; used if numberOfSectors = 0
  reservedBytes      db 6 dup(?)
  trackLayout        dw 40 dup(0)  ; specific track data
ParameterStruc ends
