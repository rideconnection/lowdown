Date::DATE_FORMATS[:default]        = '%Y-%m-%d'
Date::DATE_FORMATS[:mdy]            = '%m-%d-%Y'
Date::DATE_FORMATS[:ym]             = '%Y-%m'
Date::DATE_FORMATS[:long]           = '%B %d, %Y'
Time::DATE_FORMATS[:pretty]         = lambda { |time| time.strftime("%a, %b %e at %l:%M") + time.strftime("%p").downcase }
Time::DATE_FORMATS[:full]           = '%a, %b %e %Y at %l:%M %p'
Time::DATE_FORMATS[:time_only]      = '%l:%M %p'
Time::DATE_FORMATS[:time_only_csv]  = '%I:%M %p'
