# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bagel is a tool that helps iOS developers debug web request calls.  It consists of a Mac app that displays the requests and an iOS framework that apps install and implement that provides the info.  The framework swizzles some methods so it can listen to all the traffic, then will find the Mac app and provide the information to the mac app to display.

There is also a POC / test implementation in the test folder.
