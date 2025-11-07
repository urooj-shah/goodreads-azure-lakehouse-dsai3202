let 
    parts = Text.Split([date_added], " "),
    mon = parts{1},
    day = parts{2},
    time = parts{3},
    offset = parts{4},
    yr = parts{5},
    // convert month name → month number
    monNum = Date.Month(Date.FromText(mon & " 01, " & yr)),
    // fix offset → "-0700" → "-07:00"
    offsetIso = Text.Insert(offset, 3, ":"),
    // build ISO string: "2015-03-17T13:18:31-07:00"
    iso = yr & "-" & Text.PadStart(Text.From(monNum),2,"0") & "-" & 
          Text.PadStart(day,2,"0") & "T" & time & offsetIso
in
    iso
