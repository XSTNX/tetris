ifndef ASSUMESEG_INC
ASSUMESEG_INC = 1

allSegments group code, constData, data
    assume cs:allSegments, ds:allSegments, es:nothing, ss:allSegments

endif
