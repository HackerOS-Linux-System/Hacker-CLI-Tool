package hackeros

get_translations_main :: proc(lang: string) -> map[string]string {
    trans: map[string]string
    switch lang {
        case "pl":
            trans = pl_translations()
        case "en":
            trans = en_translations()
        case "de":
            trans = de_translations()
        case "fr":
            trans = fr_translations()
        case "es":
            trans = es_translations()
            // case "it":
            //     trans = it_translations()
            // case "ru":
            //     trans = ru_translations()
            // case "zh":
            //     trans = zh_translations()
            // case "ja":
            //     trans = ja_translations()
            // case "ko":
            //     trans = ko_translations()
            // case "pt":
            //     trans = pt_translations()
            // case "ar":
            //     trans = ar_translations()
            // case "hi":
            //     trans = hi_translations()
        case:
            trans = pl_translations() // Domyślnie polski
    }
    return trans
}

