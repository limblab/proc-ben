# loadTDfromXDS

`loadTDfromXDS` will give you a trial_data file from an XDS filename and a params struct. It depends on `processXDS`, `processXDSspikes`, and [TrialData](https://github.com/mattperich/TrialData).

Note: if your XDS file doesn't have .units and .analog, the command won't work. You can create an XDS file that contains .units and .analog using [xdsplus](https://github.com/limblab/proc-ben/tree/master/xdsplus).
