function ConvertFrom-WebkitTimeStamp ([double]$timestamp) {
    #timestamp is microseconds since Jan 1st 1601
    $basetime = [DateTime]::new(1601,1,1,0,0,0,0,[System.DateTimeKind]::Utc);
    return $basetime.AddMilliseconds( $timestamp / 1000 ).ToLocalTime();
}