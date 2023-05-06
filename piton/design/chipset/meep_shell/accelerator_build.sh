#!/bin/bash

#Use this script to call protosyn

CORE=cohort

# With perf counters

# 2 ariane + 2 empty cohorts
#make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep"

# 2 ariane + 2 sha
# make protosyn CORE=$CORE XTILES=2 YTILES=2 COHORT_TILES=2 PROTO_OPTIONS="--meep --define COHORT_ACC_SHA,PITONSYS_MEEP"

# 2 ariane + 2 aes
# make protosyn CORE=$CORE XTILES=2 YTILES=2 COHORT_TILES=2 PROTO_OPTIONS="--meep --define COHORT_ACC_AES,PITONSYS_MEEP"

# 2 ariane + 2 h264
make protosyn CORE=$CORE XTILES=2 YTILES=2 COHORT_TILES=2 PROTO_OPTIONS="--meep --define COHORT_ACC_H264,PITONSYS_MEEP"

# 2 ariane + 2 MAPLE
#make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep --define DCP_AES,PITONSYS_MEEP"


# Without Performance Counters

# 2 ariane + 2 empty cohorts
# make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep --define DCP_MIN_MAPLE,PITONSYS_MEEP"

# 2 ariane + 2 sha
#make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep --define COHORT_ACC_SHA,DCP_MIN_MAPLE,PITONSYS_MEEP"

# 2 ariane + 2 aes
#make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep --define COHORT_ACC_AES,DCP_MIN_MAPLE,PITONSYS_MEEP"

# 2 ariane + 2 MAPLE
#make protosyn CORE=$CORE XTILES=2 YTILES=2 PROTO_OPTIONS="--meep --define DCP_AES,DCP_MIN_MAPLE,PITONSYS_MEEP"
