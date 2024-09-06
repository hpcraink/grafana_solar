#!/usr/bin/env python3
import time
today=time.localtime()

# German settings
mail_from_address='set_correct@from_address.domain.name'
mail_subject="Solare Produktion am"
mail_today=f'{today.tm_mday}.{today.tm_mon}.{today.tm_year}'
mail_html_body="""\
<html><head></head>
  <body>
     <div style="font-family:Verdana;font-size:12px;">
       <div>Hallo,</div>
       <div>anbei die Daten vom {tag}: Es wurden heute <b>{kWh_today:.2f} kWh Strom</b> produziert, d.h. {percentMax_kWh:.1f}% vom höchsten, je erreichten Wert ({kWh_max_ever:.2f} kWh am {best_day}).</div>
       <div>Die maximale Leistung war {max_kW_today:.2f} kW, d.h {percentPeak_kW:.1f}% vom Peak ({peak_kW:.2f} kW), und {percentMaxEver_kW:.1f}% vom höchsten, je erreichten Wert ({kW_max_ever:.2f} kW).</div>
       <div style="color:red">{error}</div>
       <div>Lieber Gruss,</div>
       <div>Python</div>
     </div>
     <img src='cid:{msg_cid}' />
  </body>
</html>"""
