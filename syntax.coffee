query =
	get: {agreement: 'a'}
	where:
		a: {agrActNo, custNo, frDt: {gte: from}, frDt: {lte: to}}
	leftJoin: [{ord: 'o'}, {ordNo: 'ordNo'}]
	fields:
		a: ['frDt', 'ordNo', 'R2', 'ProdNo', 'CustNo', 'Desc', 'ToTm', 'FrTm',
				'AgrActNo', 'AgrNo', 'R1', 'TransGr', 'Txt1', 'Txt2', 'NoInvoAb', 'Fin']
		o: ['OrdTp', 'Gr3', 'Gr5']





	fields:
		a: "frDt.ordNo.R2.ProdNo.CustNo.Desc.ToTm.FrTm.AgrActNo.AgrNo.R1.TransGr.
				Txt1.Txt2.NoInvoAb.Fin"
		o: "OrdTp.Gr3.Gr5"
