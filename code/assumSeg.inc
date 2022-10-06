ifndef assumSeg_inc
assumSeg_inc = 1

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:nothing, ss:allSegments

endif
