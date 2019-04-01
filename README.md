# ABB-Home-Assistant-Usage
Usage meter for Home Assistant

See the ABB Usage Meter Instructions for Home Assistant PDF file for iinstructions on how to use this repo. When the meter is added you can display usage on a lovelace card in Home Assistant.

Pre-requisites
1.	Needs to be running on a ‘regular’ linux distribution (not HassOS). This is because of number 2 below.
2.	The usage retrieval uses a bash script to retrieve the usage json file from Aussie Broadband. This then creates a sensor abb_usage
3.	Your Home Assistant installation needs to have along term access token
4.	The Lovelace cards I supply require 2 custom cards.
config-template-card and bar-card available here:

https://github.com/custom-cards/config-template-card

https://github.com/custom-cards/bar-card


