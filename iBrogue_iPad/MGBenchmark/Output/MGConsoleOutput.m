/*
 * Copyright (c) 2013 Mattes Groeger
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "MGConsoleOutput.h"
#import "MGBenchmarkSession.h"

@implementation MGConsoleOutput

- (id)init
{
	self = [super init];

	if (self)
	{
		_stepFormat = @"<< BENCHMARK [${sessionName}/${stepName}] ${passedTime} (step ${stepCount}) >>";
		_totalFormat = @"<< BENCHMARK [${sessionName}/total] ${passedTime} (${stepCount} steps, average ${averageTime}) >>";
		_timeFormat = @"%.5fs";
		_timeMultiplier = 1;
	}

	return self;
}

- (void)sessionStarted:(MGBenchmarkSession *)session
{
	_session = session;
}

- (void)passedTime:(NSTimeInterval)passedTime forStep:(NSString *)stepName
{
	[self logWithFormat:_stepFormat andReplacement:@{
			@"sessionName": _session.name,
			@"stepName": stepName,
			@"passedTime": [self formatTime:passedTime],
			@"stepCount": @(_session.stepCount)
	}];
}

- (void)totalTime:(NSTimeInterval)passedTime
{
	[self logWithFormat:_totalFormat andReplacement:@{
			@"sessionName": _session.name,
			@"passedTime": [self formatTime:passedTime],
			@"stepCount": @(_session.stepCount),
			@"averageTime": [self formatTime:_session.averageTime]
	}];
}

- (NSString *)formatTime:(NSTimeInterval)time
{
	return [NSString stringWithFormat:_timeFormat, time * _timeMultiplier];
}

- (void)logWithFormat:(NSString *)format andReplacement:(NSDictionary *)replacement
{
	NSLog(@"%@", [self string:format withKeyValueReplacement:replacement]);
}

- (NSString *)string:(NSString *)string withKeyValueReplacement:(NSDictionary *)replacement
{
	for (NSString *key in [replacement allKeys])
	{
		id value = [replacement objectForKey:key];

		string = [string
					stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", key]
					withString:[NSString stringWithFormat:@"%@", value]];
	}

	return string;
}

@end